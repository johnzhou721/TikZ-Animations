-- parametric.lua
local mm = require "linalg"
local ENV_ = {}
for k, v in pairs(_G) do ENV_[k] = v end
for k, v in pairs(mm) do ENV_[k] = v end
for k, v in pairs(math) do ENV_[k] = v end

local segments = {}
local observer_dir = { { 0, 0, -1, 1} }
local observer_pos = { { 0, 0, 0, 1} }

local function single_string_function(expr)
    local func = load(
        ("return function(u) return (%s) end"):format(expr),
        "example",
        "t",
        ENV_
    )
    if not func then
        error("Failed to parse expression: " .. expr)
        return
    end
    local ok, result = pcall(func)
    if not ok then
        error("Error evaluating expression: " .. result)
        return
    end
    if type(result) ~= "function" then
        error("Expected a function, got: " .. type(result))
        return
    end

    return result
end

local function double_string_function(expr)
    local func = load(
        ("return function(u,v) return (%s) end"):format(expr),
        "example",
        "t",
        ENV_
    )
    if not func then
        error("Failed to parse expression: " .. expr)
        return
    end
    local ok, result = pcall(func)
    if not ok then
        error("Error evaluating expression: " .. result)
        return
    end
    if type(result) ~= "function" then
        error("Expected a function, got: " .. type(result))
        return
    end

    return result
end

local function single_string_expression(str)
    if type(str) ~= "string" then
        error("single_string_expression: expected a string, got " .. type(str) .. " (" .. tostring(str) .. ")")
    end
    local chunk, err = load(("return %s"):format(str), "expression", "t", ENV_)
    if not chunk then
        error("Failed to parse expression: " .. tostring(str) .. "\nError: " .. tostring(err))
    end
    local ok, result = pcall(chunk)
    if not ok then
        error("Error evaluating expression: " .. tostring(result))
    end
    return result
end

function mp.lmt_curve_generate()
    local start          = single_string_expression(tostring(metapost.getparameterset("ustart")))
    local stop           = single_string_expression(tostring(metapost.getparameterset("ustop")))
    local samples        = single_string_expression(tostring(metapost.getparameterset("usamples")))
    local x              = single_string_function(metapost.getparameterset("fx"))
    local y              = single_string_function(metapost.getparameterset("fy"))
    local z              = single_string_function(metapost.getparameterset("fz"))
    local transformation = single_string_expression(metapost.getparameterset("transformation"))
    local draw           = metapost.getparameterset("drawcommands")

    local step = (stop - start) / (samples - 1)
    local result = {}
    

    local function parametric_curve(u)
        return { { x(u), y(u), z(u), 1 } }
    end

    for i = 0, samples - 2 do
        local u = start + i * step
        local A = parametric_curve(u)
        local B = parametric_curve(u+step)
        local the_segment = mm.matrix_multiply({ A[1], B[1] }, transformation)
        table.insert(
            segments, 
            { 
                segment = the_segment, 
                draw_options = draw
            }
        )
    end
end

function mp.lmt_surface_generate()
    local start_u        = single_string_expression(tostring(metapost.getparameterset("ustart")))
    local stop_u         = single_string_expression(tostring(metapost.getparameterset("ustop")))
    local samples_u      = single_string_expression(tostring(metapost.getparameterset("usamples")))
    local start_v        = single_string_expression(tostring(metapost.getparameterset("vstart")))
    local stop_v         = single_string_expression(tostring(metapost.getparameterset("vstop")))
    local samples_v      = single_string_expression(tostring(metapost.getparameterset("vsamples")))
    local x              = double_string_function(metapost.getparameterset("fx"))
    local y              = double_string_function(metapost.getparameterset("fy"))
    local z              = double_string_function(metapost.getparameterset("fz"))
    local transformation = single_string_expression(metapost.getparameterset("transformation"))
    local draw           = metapost.getparameterset("drawcommands")
    local fill           = metapost.getparameterset("fillcommands")

    local step_u = (stop_u - start_u) / (samples_u - 1)
    local step_v = (stop_v - start_v) / (samples_v - 1)

    for i = 0, samples_u - 2 do
        for j = 0, samples_v - 2 do
            local u1 = start_u + i * step_u
            local u2 = start_u + (i + 1) * step_u
            local v1 = start_v + j * step_v
            local v2 = start_v + (j + 1) * step_v

            local A = { { x(u1, v1), y(u1, v1), z(u1, v1), 1 } }
            local B = { { x(u2, v1), y(u2, v1), z(u2, v1), 1 } }
            local D = { { x(u2, v2), y(u2, v2), z(u2, v2), 1 } }
            local C = { { x(u1, v2), y(u1, v2), z(u1, v2), 1 } }

            A = mm.matrix_multiply(A, transformation)
            B = mm.matrix_multiply(B, transformation)
            C = mm.matrix_multiply(C, transformation)
            D = mm.matrix_multiply(D, transformation)

            local segment1 = { A[1], B[1] , D[1] }
            local segment2 = { A[1], C[1] , D[1] }
            table.insert(
                segments, 
                { 
                    segment = segment1, 
                    draw_options = draw,
                    fill_options = fill
                }
            )
            table.insert(
                segments, 
                { 
                    segment = segment2, 
                    draw_options = draw,
                    fill_options = fill
                }
            )
        end
    end
end

local function is_point_in_triangle(point,triangle)
    local P,Q,R = table.unpack(triangle)
    P,Q,R = {P},{Q},{R}
    local cross_PQ = mm.cross_product(
        mm.matrix_subtract(Q,P)
        ,point
    )
    local cross_QR = mm.cross_product(
        mm.matrix_subtract(R,Q)
        ,point
    )
    local cross_RP = mm.cross_product(
        mm.matrix_subtract(P,R)
        ,point
    )
    local sign_1 = mm.sign(cross_PQ[1][1])
    local sign_2 = mm.sign(cross_QR[1][1])
    local sign_3 = mm.sign(cross_RP[1][1])
    local sign_4 = mm.sign(cross_PQ[1][2])
    local sign_5 = mm.sign(cross_QR[1][2])
    local sign_6 = mm.sign(cross_RP[1][2])
    local sign_7 = mm.sign(cross_PQ[1][3])
    local sign_8 = mm.sign(cross_QR[1][3])
    local sign_9 = mm.sign(cross_RP[1][3])
    if (
        (sign_1 == sign_2 and sign_2 == sign_3) and
        (sign_4 == sign_5 and sign_5 == sign_6) and
        (sign_7 == sign_8 and sign_8 == sign_9)
    ) then
        return true
    else
        return false
    end
end

local function compare_segments(triangle_1,triangle_2)
    if #triangle_1.segment == 1 or #triangle_2.segment == 1 then
        local function depth_mid(seg)
            if #seg == 1 then
                -- line/curve segment: midpoint of S, E
                local S = seg[1]
                local mid = {{
                    S[1],S[2],S[3],1
                }}
                return mm.dot_product(mid, observer_dir)
            else
                -- triangle: centroid of P, Q, R
                local P, Q = seg[1], seg[2]
                local cent = {{
                    (P[1] + Q[1]) / 2,
                    (P[2] + Q[2]) / 2,
                    (P[3] + Q[3]) / 2,
                    1
                }}
                return mm.dot_product(cent, observer_dir)
            end
        end
        local a = depth_mid(triangle_1.segment)
        local b = depth_mid(triangle_2.segment)
        return a > b
    end
    -- 1) if *either* is a 2‐point line/curve (#==3), depth‐sort by midpoint along observer
    if #triangle_1.segment == 2 or #triangle_2.segment == 2 then
        local function depth_mid(seg)
            if #seg == 2 then
                -- line/curve segment: midpoint of S, E
                local S, E = seg[1], seg[2]
                local mid = {{
                    (S[1] + E[1]) / 2,
                    (S[2] + E[2]) / 2,
                    (S[3] + E[3]) / 2,
                    1
                }}
                return mm.dot_product(mid, observer_dir)
            else
                -- triangle: centroid of P, Q, R
                local P, Q, R = seg[1], seg[2], seg[3]
                local cent = {{
                    (P[1] + Q[1] + R[1]) / 3,
                    (P[2] + Q[2] + R[2]) / 3,
                    (P[3] + Q[3] + R[3]) / 3,
                    1
                }}
                return mm.dot_product(cent, observer_dir)
            end
        end
        local a = depth_mid(triangle_1.segment)
        local b = depth_mid(triangle_2.segment)
        return a > b
    end


    if #triangle_1.segment > 3 or #triangle_2.segment > 3 then
        local function depth_mid(segment)
            local x, y, z = 0, 0, 0
            local n = #segment
            for i = 1, n do
                local pt = segment[i]
                x = x + pt[1]
                y = y + pt[2]
                z = z + pt[3]
            end
            local centroid = {{x / n, y / n, z / n, 1}}
            return mm.dot_product(centroid, observer_dir)
        end
        return depth_mid(triangle_1.segment) > depth_mid(triangle_2.segment)
    end
    ---
    local P_1, Q_1, R_1 = table.unpack(triangle_1.segment)
    local P_2, Q_2, R_2 = table.unpack(triangle_2.segment)
    P_1, Q_1, R_1 = {P_1}, {Q_1}, {R_1}
    P_2, Q_2, R_2 = {P_2}, {Q_2}, {R_2}


    local observer_basis = mm.get_observer_plane_basis(observer_dir)
    local P_1_projection = mm.project_point_onto_basis(P_1,observer_basis)
    local Q_1_projection = mm.project_point_onto_basis(Q_1,observer_basis)
    local R_1_projection = mm.project_point_onto_basis(R_1,observer_basis)
    local P_2_projection = mm.project_point_onto_basis(P_2,observer_basis)
    local Q_2_projection = mm.project_point_onto_basis(Q_2,observer_basis)
    local R_2_projection = mm.project_point_onto_basis(R_2,observer_basis)
    -- compare to triangle 1
    local P_test = is_point_in_triangle(P_2_projection,{P_1_projection[1],Q_1_projection[1],R_1_projection[1]})
    local Q_test = is_point_in_triangle(Q_2_projection,{P_1_projection[1],Q_1_projection[1],R_1_projection[1]})
    local R_test = is_point_in_triangle(R_2_projection,{P_1_projection[1],Q_1_projection[1],R_1_projection[1]})
    if (P_test or Q_test or R_test) then
        local test
        if P_test then
            test = "P"
        else
            if Q_test then
                test = "Q"
            else
                test = "R"
            end
        end
        local normal_1 = mm.cross_product(
            mm.matrix_subtract(Q_1,P_1)
            ,mm.matrix_subtract(R_1,P_1)
        )
        if mm.dot_product(normal_1,observer_dir) < 1 then
            normal_1 = mm.matrix_scale(-1,normal_1)
        end
        local signed_distance_to_plane
        if test == "P" then
            signed_distance_to_plane = mm.norm(
                mm.matrix_add(
                    P_2
                    ,mm.matrix_scale(-1,P_2_projection)
                )
            )
            if (
                mm.dot_product(
                    mm.matrix_subtract(P_2,P_2_projection)
                    ,normal_1
                ) < 1
            ) then 
                signed_distance_to_plane = -signed_distance_to_plane
            end
            if mm.sign(signed_distance_to_plane) == "positive" then
                return true
            else
                return false
            end
        end
        if test == "Q" then
            signed_distance_to_plane = mm.norm(
                mm.matrix_subtract(Q_2,Q_2_projection)
            )
            if (
                mm.dot_product(
                    mm.matrix_subtract(Q_2,Q_2_projection)
                    ,normal_1
                ) < 0
            ) then 
                signed_distance_to_plane = -signed_distance_to_plane
            end
            if mm.sign(signed_distance_to_plane) == "positive" then
                return true
            else
                return false
            end
        end
        if test == "R" then
            signed_distance_to_plane = mm.norm(
                mm.matrix_subtract(R_2,R_2_projection)
            )
            if (
                mm.dot_product(
                    mm.matrix_subtract(R_2,R_2_projection)
                    ,normal_1
                ) < 0
            ) then 
                signed_distance_to_plane = -signed_distance_to_plane
            end
            if mm.sign(signed_distance_to_plane) == "positive" then
                return true
            else
                return false
            end
        end
    else
        local midpoint_1 = mm.midpoint({P_1[1],Q_1[1],R_1[1]})
        local midpoint_2 = mm.midpoint({P_2[1],Q_2[1],R_2[1]})
        local dot_product_1 = mm.dot_product(midpoint_1,observer_dir)
        local dot_product_2 = mm.dot_product(midpoint_2,observer_dir)
        return dot_product_1 > dot_product_2
    end
    return false -- test
end

function mp.lmt_render_segments_generate()
    table.sort(segments, compare_segments)
    mp.print("path lmt_tmp ;")
    for _, segment in ipairs(segments) do
        if #segment.segment == 2 then
            local S = segment.segment
            local draw_options = segment.draw_options
            mp.print(("lmt_tmp := (%f,%f) -- (%f,%f) ; draw lmt_tmp scaled 1cm %s ;"):format(S[1][1], S[1][2], S[2][1], S[2][2], draw_options))
        end
        if #segment.segment == 3 then
            local P, Q, R = table.unpack(segment.segment)
            local draw_options = segment.draw_options
            local fill_options = segment.fill_options
            mp.print(("lmt_tmp := (%f,%f) -- (%f,%f) -- (%f,%f) -- cycle ; fill lmt_tmp scaled 1cm %s ; draw lmt_tmp scaled 1cm %s ;"):format(
                P[1], P[2], Q[1], Q[2], R[1], R[2], fill_options, draw_options
            ))
        end
    end
    segments = {}
end