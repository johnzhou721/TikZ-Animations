local mm = require "matrix_math"

local ss = {}

local observer = {{0,0,-1,1}}

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

function ss.compare_triangles(triangle_1,triangle_2)
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
                return mm.dot_product(mid, observer)
            else
                -- triangle: centroid of P, Q, R
                local P, Q, R = seg[1], seg[2], seg[3]
                local cent = {{
                    (P[1] + Q[1] + R[1]) / 3,
                    (P[2] + Q[2] + R[2]) / 3,
                    (P[3] + Q[3] + R[3]) / 3,
                    1
                }}
                return mm.dot_product(cent, observer)
            end
        end

        return depth_mid(triangle_1.segment) > depth_mid(triangle_2.segment)
    end
    ---
    local P_1, Q_1, R_1 = table.unpack(triangle_1.segment)
    local P_2, Q_2, R_2 = table.unpack(triangle_2.segment)
    P_1, Q_1, R_1 = {P_1}, {Q_1}, {R_1}
    P_2, Q_2, R_2 = {P_2}, {Q_2}, {R_2}


    local observer_basis = mm.get_observer_plane_basis(observer)
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
        if mm.dot_product(normal_1,observer) < 1 then
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
        local dot_product_1 = mm.dot_product(midpoint_1,observer)
        local dot_product_2 = mm.dot_product(midpoint_2,observer)
        return dot_product_1 > dot_product_2
    end
    return false -- test
end

return ss