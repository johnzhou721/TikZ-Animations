local po = {}

local la = require("linear_algebra")


po.segments = {}
po.observer_dir = { { 0, 0, -1, 0 } }
po.observer_pos = { { 0, 0, 0, 0 } }


function po.single_string_function(str)
    if not str or str == "" then
        return nil
    end
    return load(("return function(u) return %s end"):format(str))()
end

function po.double_string_function(str)
    if not str or str == "" then
        return nil
    end
    return load(("return function(u,v) return %s end"):format(str))()
end

function po.triple_string_function(str)
    if not str or str == "" then
        return nil
    end
    return load(("return function(u,v,w) return %s end"):format(str))()
end

function po.append_curve(hash)
    local u_start   = tonumber(hash.u_start)
    local u_end     = tonumber(hash.u_end)
    local u_samples = tonumber(hash.u_samples)
    local fx_str    = hash.fx
    local fy_str    = hash.fy
    local fz_str    = hash.fz
    local draw_options   = hash.draw_options
    local name = hash.name

    
    local fx = po.single_string_function(fx_str)
    local fy = po.single_string_function(fy_str)
    local fz = po.single_string_function(fz_str)

    local u_step = (u_end - u_start) / (u_samples - 1)
    local function parametric_curve(u)
        return {fx(u),fy(u),fz(u),1}
    end

    for i = 0, u_samples - 2 do
        local u = u_start + i * u_step
        local A = parametric_curve(u)
        local B = parametric_curve(u+u_step)
        table.insert(po.segments,{{A,B},draw_options, name})
    end
end

function po.append_surface(
    params
)
    local u_start      = tonumber(params.u_start)
    local u_end        = tonumber(params.u_end)
    local u_samples    = tonumber(params.u_samples)
    local v_start      = tonumber(params.v_start)
    local v_end        = tonumber(params.v_end)
    local v_samples    = tonumber(params.v_samples)
    local fx_str       = params.fx
    local fy_str       = params.fy
    local fz_str       = params.fz
    local fill_options = params.fill_options
    local draw_options = params.draw_options
    local name         = params.name

    local fx = po.double_string_function(fx_str)
    local fy = po.double_string_function(fy_str)
    local fz = po.double_string_function(fz_str)

    local u_step = (u_end - u_start) / (u_samples - 1)
    local v_step = (v_end - v_start) / (v_samples - 1)

    local function parametric_surface(u,v)
        return {fx(u,v),fy(u,v),fz(u,v),1}
    end

    for i = 0, u_samples - 2 do
        local u = u_start + i * u_step
        for j = 0, v_samples - 2 do
            local v = v_start + j * v_step
            local A = parametric_surface(u, v)
            local B = parametric_surface(u + u_step, v)
            local C = parametric_surface(u, v + v_step)
            local D = parametric_surface(u + u_step, v + v_step)
            table.insert(po.segments, {{A, B, D}, {fill_options, draw_options}, name})
            table.insert(po.segments, {{A, C, D}, {fill_options, draw_options}, name})
        end
    end
end
local function get_plane_basis(vector)
    local origin = {{0,0,0,1}}
    local basis_i = po.orthogonal_vector(vector)
    basis_i = la.normalize(basis_i)
    local basis_j = la.cross(vector,basis_i)
    basis_j = la.normalize(basis_j)
    return {origin,basis_i,basis_j}
end

function po.is_point_in_triangle(point,triangle)
    local P,Q,R = table.unpack(triangle)
    local cross_PQ = la.cross(la.add(Q,la.scale(-1,P)),point)
    local cross_QR = la.cross(la.add(R,la.scale(-1,Q)),point)
    local cross_RP = la.cross(la.add(P,la.scale(-1,R)),point)
    local sign_1 = la.sign(cross_PQ[1][1])
    local sign_2 = la.sign(cross_QR[1][1])
    local sign_3 = la.sign(cross_RP[1][1])
    local sign_4 = la.sign(cross_PQ[1][2])
    local sign_5 = la.sign(cross_QR[1][2])
    local sign_6 = la.sign(cross_RP[1][2])
    local sign_7 = la.sign(cross_PQ[1][3])
    local sign_8 = la.sign(cross_QR[1][3])
    local sign_9 = la.sign(cross_RP[1][3])
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

function po.compare_segments(S1, S2)
    if #S1[1] == 2 or #S2[1] == 2 then
        local mid1 = la.midpoint({{S1[1][1]},{S1[1][2]}})
        local mid2 = la.midpoint({{S2[1][1]},{S2[1][2]}}) 
        if #S1[1] == 3 then
            local mid1 = la.midpoint({{S1[1][1]},{S1[1][2]},{S1[1][3]}})
            local mid2 = la.midpoint({{S2[1][1]},{S2[1][2]}})
        elseif #S2[1] == 3 then
            local mid1 = la.midpoint({{S1[1][1]},{S1[1][2]}})
            local mid2 = la.midpoint({{S2[1][1]},{S2[1][2]},{S2[1][3]}})
        end
        local dot1 =  la.inner(mid1,po.observer_dir)
        local dot2 =  la.inner(mid2,po.observer_dir)
        return dot1 < dot2
    end

    local P1, Q1, R1 = table.unpack(S1[1])
    local P2, Q2, R2 = table.unpack(S2[1])
    P1, Q1, R1 = {P1}, {Q1}, {R1}
    P2, Q2, R2 = {P2}, {Q2}, {R2}
    local observer_basis = get_plane_basis(po.observer_dir)
    local projP1 = po.project_point_onto_basis(P1,observer_basis)
    local projQ1 = po.project_point_onto_basis(Q1,observer_basis)
    local projR1 = po.project_point_onto_basis(R1,observer_basis)
    local projP2 = po.project_point_onto_basis(P2,observer_basis)
    local projQ2 = po.project_point_onto_basis(Q2,observer_basis)
    local projR2 = po.project_point_onto_basis(R2,observer_basis)
    
    local testP = po.is_point_in_triangle(projP2,{projP1,projQ1,projR1})
    local testQ = po.is_point_in_triangle(projQ2,{projP1,projQ1,projR1})
    local testR = po.is_point_in_triangle(projR2,{projP1,projQ1,projR1})

    if (testP or testQ or testR) then
        local test
        if testP then
            test = "P"
        else
            if testQ then
                test = "Q"
            else
                test = "R"
            end
        end
        local normal_1 = la.cross(
            la.add(Q1,la.scale(-1,P1)),
            la.add(R1,la.scale(-1,P1))
        )
        if la.inner(normal_1,po.observer_dir) > 0 then
            normal_1 = la.scale(-1,normal_1)
        end
        local signed_distance_to_plane
        if test == "P" then
            signed_distance_to_plane = la.norm(
                la.add(
                    P2
                    ,la.scale(
                        -1,projP2
                    )
                )
            )
            if (
                la.inner(
                    la.add(
                        P2
                        ,la.scale(
                            -1,projP2
                        )
                    )
                    ,normal_1
                ) > 0
            ) then 
                signed_distance_to_plane = -signed_distance_to_plane
            end
            if la.sign(signed_distance_to_plane) == "positive" then
                return true
            else
                return false
            end
        end
        if test == "Q" then
            signed_distance_to_plane = la.norm(
                la.add(
                    Q2
                    ,la.scale(
                        -1,projQ2
                    )
                )
            )
            if (
                la.inner(
                    la.add(
                        Q2
                        ,la.scale(
                            -1,projQ2
                        )
                    )
                    ,normal_1
                ) > 0
            ) then 
                signed_distance_to_plane = -signed_distance_to_plane
            end
            if la.sign(signed_distance_to_plane) == "positive" then
                return true
            else
                return false
            end
        end
        if test == "R" then
            signed_distance_to_plane = la.norm(
                la.add(
                    R2
                    ,la.scale(
                        -1,projR2
                    )
                )
            )
            if (
                la.inner(
                    la.add(
                        R2
                        ,la.scale(
                            -1,projR2
                        )
                    )
                    ,normal_1
                ) > 0
            ) then 
                signed_distance_to_plane = -signed_distance_to_plane
            end
            if la.sign(signed_distance_to_plane) == "positive" then
                return true
            else
                return false
            end
        end
    else
        local midpoint_1 = la.midpoint({P1,Q1,R1})
        local midpoint_2 = la.midpoint({P2,Q2,R2})
        local dot_product_1 = la.inner(midpoint_1,po.observer_dir)
        local dot_product_2 = la.inner(midpoint_2,po.observer_dir)
        return dot_product_1 < dot_product_2
    end
end

function po.orthogonal_vector(u)
    local v
    if (u[1][1]~=0 and u[1][2]==0 and u[1][3]==0) then
        v = la.cross(u,{{0,1,0,1}})
    else
        v = la.cross(u,{{1,0,0,1}})
    end
    local result = v
    return result
end

function po.orthogonal_vector_projection(base_vector,projected_vector)
    local scale = (
        la.inner(base_vector,projected_vector) / 
        la.inner(base_vector,base_vector)
    )
    return {{
        base_vector[1][1]*scale,
        base_vector[1][2]*scale,
        base_vector[1][3]*scale,
        1
    }}
end

function po.project_point_onto_basis(point,basis)
    local normal = la.cross(basis[2],basis[3])
    normal = la.normalize(normal)
    local vector_from_plane = po.orthogonal_vector_projection(point,normal)
    local result = {{
        point[1][1]-vector_from_plane[1][1]
        ,point[1][2]-vector_from_plane[1][2]
        ,point[1][3]-vector_from_plane[1][3],
        1
    }}
    return result
end



function po.render_segments()
    table.sort(po.segments, po.compare_segments)
    for _, seg in ipairs(po.segments) do
        if #seg[1] == 2 then
            local S3, E3 = seg[1][1], seg[1][2]
            local Sx, Sy = S3[1], S3[2]
            local Ex, Ey = E3[1], E3[2]
            local options = seg[2]
            context(
                "draw (%.4fcm,%.4fcm) -- (%.4fcm,%.4fcm)"..options,
                Sx, Sy, Ex, Ey, options
            )
        end
        if #seg[1] == 3 then
            local P, Q, R = seg[1][1], seg[1][2], seg[1][3]
            local Px, Py = P[1], P[2]
            local Qx, Qy = Q[1], Q[2]
            local Rx, Ry = R[1], R[2]
            local fill_options = seg[2][1]
            local draw_options = seg[2][2]
            -- local test = la.inner(la.midpoint({{P},{Q},{R}}),po.observer_dir) > la.inner(po.observer_pos,po.observer_dir)
            if true then
                context(
                    [[
                        path p;
                        p := (%f,%f) -- (%f,%f) -- (%f,%f) -- cycle;
                        fill p scaled 1cm
                    ]]..fill_options,
                    Px, Py, Qx, Qy, Rx, Ry
                )
                context(
                    [[
                        path p;
                        p := (%f,%f) -- (%f,%f) -- (%f,%f) -- cycle;
                        draw p scaled 1cm
                    ]]..draw_options,
                    Px, Py, Qx, Qy, Rx, Ry
                )
            end
        end
    end
    po.segments = {}
end

return po