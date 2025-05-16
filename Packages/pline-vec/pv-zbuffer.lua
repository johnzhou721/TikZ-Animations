

function get_observer_plane_basis(observer)
    local origin = {0,0,0}
    local basis_i = pv_orthogonal_vector(observer)
    basis_i = pv_normalize(basis_i)
    local basis_j = pv_cross_product(observer,basis_i)
    basis_j = pv_normalize(basis_j)
    return {origin,basis_i,basis_j}

end

function project_point_onto_basis(point,basis)
    local normal = pv_cross_product(basis[2],basis[3])
    normal = pv_normalize(normal)
    local vector_from_plane = pv_orthogonal_vector_projection(point,normal)
    local result = {
        point[1]-vector_from_plane[1]
        ,point[2]-vector_from_plane[2]
        ,point[3]-vector_from_plane[3]
    }
    return result
end

function is_point_in_triangle(point,triangle)
    local P,Q,R,temp1,temp2 = table.unpack(triangle)
    local cross_PQ = pv_cross_product(
        pv_addition(Q,pv_scalar_multiplication(P,-1))
        ,point
    )
    local cross_QR = pv_cross_product(
        pv_addition(R,pv_scalar_multiplication(Q,-1))
        ,point
    )
    local cross_RP = pv_cross_product(
        pv_addition(P,pv_scalar_multiplication(R,-1))
        ,point
    )
    local sign_1 = pv_sign(cross_PQ[1])
    local sign_2 = pv_sign(cross_QR[1])
    local sign_3 = pv_sign(cross_RP[1])
    local sign_4 = pv_sign(cross_PQ[2])
    local sign_5 = pv_sign(cross_QR[2])
    local sign_6 = pv_sign(cross_RP[2])
    local sign_7 = pv_sign(cross_PQ[2])
    local sign_8 = pv_sign(cross_QR[2])
    local sign_9 = pv_sign(cross_RP[2])
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

function compare_triangles(triangle_1,triangle_2)
    local P_1,Q_1,R_1,color_1,options_1 = table.unpack(triangle_1)
    local P_2,Q_2,R_2,color_2,options_2 = table.unpack(triangle_2)
    local observer_basis = get_observer_plane_basis(observer)
    local P_1_projection = project_point_onto_basis(P_1,observer_basis)
    local Q_1_projection = project_point_onto_basis(Q_1,observer_basis)
    local R_1_projection = project_point_onto_basis(R_1,observer_basis)
    local P_2_projection = project_point_onto_basis(P_2,observer_basis)
    local Q_2_projection = project_point_onto_basis(Q_2,observer_basis)
    local R_2_projection = project_point_onto_basis(R_2,observer_basis)
    -- compare to triangle 1
    local P_test = is_point_in_triangle(P_2_projection,{P_1_projection,Q_1_projection,R_1_projection})
    local Q_test = is_point_in_triangle(Q_2_projection,{P_1_projection,Q_1_projection,R_1_projection})
    local R_test = is_point_in_triangle(R_2_projection,{P_1_projection,Q_1_projection,R_1_projection})
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
        local normal_1 = pv_cross_product(
            pv_addition(
                Q_1
                ,pv_scalar_multiplication(P_1,-1)
            )
            ,pv_addition(
                R_1
                ,pv_scalar_multiplication(P_1,-1)
            )
        )
        if pv_dot_product(normal_1,observer) < 0 then
            normal_1 = pv_scalar_multiplication(normal_1,-1)
        end
        local signed_distance_to_plane
        if test == "P" then
            signed_distance_to_plane = pv_norm(
                pv_addition(
                    P_2
                    ,pv_scalar_multiplication(
                        P_2_projection,-1
                    )
                )
            )
            if (
                pv_dot_product(
                    pv_addition(
                        P_2
                        ,pv_scalar_multiplication(
                            P_2_projection,-1
                        )
                    )
                    ,normal_1
                ) < 0
            ) then 
                signed_distance_to_plane = -signed_distance_to_plane
            end
            if pv_sign(signed_distance_to_plane) == "positive" then
                return true
            else
                return false
            end
        end
        if test == "Q" then
            signed_distance_to_plane = pv_norm(
                pv_addition(
                    Q_2
                    ,pv_scalar_multiplication(
                        Q_2_projection,-1
                    )
                )
            )
            if (
                pv_dot_product(
                    pv_addition(
                        Q_2
                        ,pv_scalar_multiplication(
                            Q_2_projection,-1
                        )
                    )
                    ,normal_1
                ) < 0
            ) then 
                signed_distance_to_plane = -signed_distance_to_plane
            end
            if pv_sign(signed_distance_to_plane) == "positive" then
                return true
            else
                return false
            end
        end
        if test == "R" then
            signed_distance_to_plane = pv_norm(
                pv_addition(
                    R_2
                    ,pv_scalar_multiplication(
                        R_2_projection,-1
                    )
                )
            )
            if (
                pv_dot_product(
                    pv_addition(
                        R_2
                        ,pv_scalar_multiplication(
                            R_2_projection,-1
                        )
                    )
                    ,normal_1
                ) < 0
            ) then 
                signed_distance_to_plane = -signed_distance_to_plane
            end
            if pv_sign(signed_distance_to_plane) == "positive" then
                return true
            else
                return false
            end
        end
    else
        local midpoint_1 = pv_midpoint({P_1,Q_1,R_1})
        local midpoint_2 = pv_midpoint({P_2,Q_2,R_2})
        local dot_product_1 = pv_dot_product(midpoint_1,observer)
        local dot_product_2 = pv_dot_product(midpoint_2,observer)
        return dot_product_1 > dot_product_2
    end
    return false -- test
end







segments = {}
function pv_append_surface(
    u_start
    ,u_end
    ,u_samples
    ,v_start
    ,v_end
    ,v_samples
    ,fx,fy,fz
    ,options
)
    local u_step = (u_end - u_start) / (u_samples - 1)
    local v_step = (v_end - v_start) / (v_samples - 1)
    local function parametric_surface(u,v)
        return {fx(u,v), fy(u,v), fz(u,v)}
    end
    for i = 0, u_samples - 2 do
        local u = u_start + i * u_step
        local color = (u - u_start) / (u_end - u_start)
        for j = 0, v_samples - 2 do
            local v = v_start + j * v_step
            local A = parametric_surface(u, v)
            local B = parametric_surface(u + u_step, v)
            local C = parametric_surface(u, v + v_step)
            local D = parametric_surface(u + u_step, v + v_step)
            -- the tables for surfaces have 5 values
            table.insert(segments, {A, B, D, color, options})
            table.insert(segments, {A, C, D, color, options})
        end
    end

end -- ends pv_append_surface

function pv_render_segments()
    table.sort(segments, compare_triangles)
    for _, seg in ipairs(segments) do
    local n = #seg; local P, Q, R, c, o = seg[1], seg[2], seg[3], seg[4], seg[5]

    tex.print('\\draw[line join=round,preaction={fill=yellow}]')
    tex.print(string.format('(%f,%f,%f)--(%f,%f,%f)--(%f,%f,%f)--cycle;',
    P[1],P[2],P[3],Q[1],Q[2],Q[3],R[1],R[2],R[3]
    ))
  end
  segments = {}
end

