function cross_product(u,v)
    local x = u[2]*v[3]-u[3]*v[2]
    local y = u[3]*v[1]-u[1]*v[3]
    local z = u[1]*v[2]-u[2]*v[1]
    local result = {x,y,z}
    return result
end

function orthogonal_vector(u)
    local v
    if (u[1]~=0 and u[2]==0 and u[3]==0) then
        v = cross_product(u,{0,1,0})
    else
        v = cross_product(u,{1,0,0})
    end
    local result = v
    return result
end

function normalize(vector)
    local the_norm = norm(vector)
    return {
        vector[1]/the_norm
        ,vector[2]/the_norm
        ,vector[3]/the_norm
    }
end

function get_observer_plane_basis(observer)
    local origin = {0,0,0}
    local basis_i = orthogonal_vector(observer)
    basis_i = normalize(basis_i)
    local basis_j = cross_product(observer,basis_i)
    basis_j = normalize(basis_j)
    return {origin,basis_i,basis_j}
end

function orthogonal_vector_projection(base_vector,projected_vector)
    local scale = (
        dot_product(base_vector,projected_vector) / 
        dot_product(base_vector,base_vector)
    )
    return {base_vector[1]*scale,base_vector[2]*scale,base_vector[3]*scale}
end

function project_point_onto_basis(point,basis)
    local normal = cross_product(basis[2],basis[3])
    normal = normalize(normal)
    local vector_from_plane = orthogonal_vector_projection(normal,point)
    local result = {
        point[1]-vector_from_plane[1]
        ,point[2]-vector_from_plane[2]
        ,point[3]-vector_from_plane[3]
    }
    return result
end

function is_point_in_triangle(point,triangle)
    local P,Q,R,temp1,temp2 = table.unpack(triangle)
    local cross_PQ = cross_product(
        addition(Q,scalar_multiplication(P,-1))
        ,addition(point,scalar_multiplication(P,-1))
    )
    local cross_QR = cross_product(
        addition(R,scalar_multiplication(Q,-1))
        ,addition(point,scalar_multiplication(Q,-1))
    )
    local cross_RP = cross_product(
        addition(P,scalar_multiplication(R,-1))
        ,addition(point,scalar_multiplication(R,-1))
    )
    local sign_1 = sign(cross_PQ[1])
    local sign_2 = sign(cross_QR[1])
    local sign_3 = sign(cross_RP[1])
    local sign_4 = sign(cross_PQ[2])
    local sign_5 = sign(cross_QR[2])
    local sign_6 = sign(cross_RP[2])
    local sign_7 = sign(cross_PQ[3])
    local sign_8 = sign(cross_QR[3])
    local sign_9 = sign(cross_RP[3])
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
    local P_1,Q_1,R_1 = table.unpack(triangle_1)
    local P_2,Q_2,R_2 = table.unpack(triangle_2)
    local observer_basis = get_observer_plane_basis(observer)
    local P_1_projection = project_point_onto_basis(P_1,observer_basis)
    local Q_1_projection = project_point_onto_basis(Q_1,observer_basis)
    local R_1_projection = project_point_onto_basis(R_1,observer_basis)
    local P_2_projection = project_point_onto_basis(P_2,observer_basis)
    local Q_2_projection = project_point_onto_basis(Q_2,observer_basis)
    local R_2_projection = project_point_onto_basis(R_2,observer_basis)
    -- compare to triangle 1
    local P_1_test = is_point_in_triangle(P_1_projection,{P_2_projection,Q_2_projection,R_2_projection})
    local Q_1_test = is_point_in_triangle(Q_1_projection,{P_2_projection,Q_2_projection,R_2_projection})
    local R_1_test = is_point_in_triangle(R_1_projection,{P_2_projection,Q_2_projection,R_2_projection})
    local P_2_test = is_point_in_triangle(P_2_projection,{P_1_projection,Q_1_projection,R_1_projection})
    local Q_2_test = is_point_in_triangle(Q_2_projection,{P_1_projection,Q_1_projection,R_1_projection})
    local R_2_test = is_point_in_triangle(R_2_projection,{P_1_projection,Q_1_projection,R_1_projection})
    
    if (P_1_test or Q_1_test or R_1_test) then
        if P_1_test then
            test = "P_1"
        else
            if Q_1_test then
                test = "Q_1"
            else
                test = "R_1"
            end
        end
        local normal_1 = cross_product(
            addition(
                Q_1
                ,scalar_multiplication(P_1,-1)
            )
            ,addition(
                R_1
                ,scalar_multiplication(P_1,-1)
            )
        )
        if dot_product(normal_1,observer) < 0 then
            normal_1 = scalar_multiplication(normal_1,-1)
        end
        local signed_distance_to_plane
        if test == "P_1" then
            signed_distance_to_plane = norm(
                addition(
                    P_2_projection
                    ,scalar_multiplication(
                        P_2,-1
                    )
                )
            )
            if (
                dot_product(
                    addition(
                        P_2_projection
                        ,scalar_multiplication(
                            P_2,-1
                        )
                    )
                    ,normal_1
                ) < 0
            ) then 
                signed_distance_to_plane = -signed_distance_to_plane
            end
            if sign(signed_distance_to_plane) == "positive" then
                return true
            else
                return false
            end
        end
        if test == "Q_1" then
            signed_distance_to_plane = norm(
                addition(
                    Q_2_projection
                    ,scalar_multiplication(
                        Q_2,-1
                    )
                )
            )
            if (
                dot_product(
                    addition(
                        Q_2_projection
                        ,scalar_multiplication(
                            Q_2,-1
                        )
                    )
                    ,normal_1
                ) < 0
            ) then 
                signed_distance_to_plane = -signed_distance_to_plane
            end
            if sign(signed_distance_to_plane) == "positive" then
                return true
            else
                return false
            end
        end
        if test == "R_1" then
            signed_distance_to_plane = norm(
                addition(
                    R_2_projection
                    ,scalar_multiplication(
                        R_2,-1
                    )
                )
            )
            if (
                dot_product(
                    addition(
                        R_2_projection
                        ,scalar_multiplication(
                            R_2,-1
                        )
                    )
                    ,normal_1
                ) < 0
            ) then 
                signed_distance_to_plane = -signed_distance_to_plane
            end
            if sign(signed_distance_to_plane) == "positive" then
                return true
            else
                return false
            end
        end
    else
        ---
        if (P_2_test or Q_2_test or R_2_test) then
            if P_2_test then
                test = "P_2"
            else
                if Q_2_test then
                    test = "Q_2"
                else
                    test = "R_2"
                end
            end
            local normal_1 = cross_product(
                addition(
                    Q_1
                    ,scalar_multiplication(P_1,-1)
                )
                ,addition(
                    R_1
                    ,scalar_multiplication(P_1,-1)
                )
            )
            if dot_product(normal_1,observer) < 0 then
                normal_1 = scalar_multiplication(normal_1,-1)
            end
            local signed_distance_to_plane
            if test == "P_2" then
                signed_distance_to_plane = norm(
                    addition(
                        P_1_projection
                        ,scalar_multiplication(
                            P_1,-1
                        )
                    )
                )
                if (
                    dot_product(
                        addition(
                            P_1_projection
                            ,scalar_multiplication(
                                P_1,-1
                            )
                        )
                        ,normal_1
                    ) < 0
                ) then 
                    signed_distance_to_plane = -signed_distance_to_plane
                end
                if sign(signed_distance_to_plane) == "positive" then
                    return true
                else
                    return false
                end
            end
            if test == "Q_2" then
                signed_distance_to_plane = norm(
                    addition(
                        Q_1_projection
                        ,scalar_multiplication(
                            Q_1,-1
                        )
                    )
                )
                if (
                    dot_product(
                        addition(
                            Q_1_projection
                            ,scalar_multiplication(
                                Q_1,-1
                            )
                        )
                        ,normal_1
                    ) < 0
                ) then 
                    signed_distance_to_plane = -signed_distance_to_plane
                end
                if sign(signed_distance_to_plane) == "positive" then
                    return true
                else
                    return false
                end
            end
            if test == "R_2" then
                signed_distance_to_plane = norm(
                    addition(
                        R_1_projection
                        ,scalar_multiplication(
                            R_1,-1
                        )
                    )
                )
                if (
                    dot_product(
                        addition(
                            R_1_projection
                            ,scalar_multiplication(
                                R_1,-1
                            )
                        )
                        ,normal_1
                    ) < 0
                ) then 
                    signed_distance_to_plane = -signed_distance_to_plane
                end
                if sign(signed_distance_to_plane) == "positive" then
                    return true
                else
                    return false
                end
            end
        else
            local midpoint_1 = midpoint({P_1,Q_1,R_1})
            local midpoint_2 = midpoint({P_2,Q_2,R_2})
            local dot_product_1 = dot_product(midpoint_1,observer)
            local dot_product_2 = dot_product(midpoint_2,observer)
            return dot_product_1 > dot_product_2
        end
    end
end

function norm(u)
    local result = math.sqrt((u[1])^2 + (u[2])^2 + (u[3])^2)
    return result
end


function addition(vector1,vector2)
    return {
        vector1[1]+vector2[1]
        ,vector1[2]+vector2[2]
        ,vector1[3]+vector2[3]
    }
end

function scalar_multiplication(vector,scalar)
    return {
        vector[1] * scalar
        ,vector[2] * scalar
        ,vector[3] * scalar
    }
end

function sign(number)
    if number >= 0 then return "positive" end
    return "negative"
end

function midpoint(triangle)
    local P,Q,R = table.unpack(triangle)
    local x = (P[1]+Q[1]+R[1])/3
    local y = (P[2]+Q[2]+R[2])/3
    local z = (P[3]+Q[3]+R[3])/3
    return {x,y,z}
end

function dot_product(u,v)
    local result = u[1]*v[1] + u[2]*v[2] + u[3]*v[3]
    return result
end



function sphere_x(longitude,latitude)
    local x = (cosd(latitude)*cosd(longitude))
    return x
end

function sphere_y(longitude,latitude)
    local y = (cosd(latitude)*sind(longitude))
    return y
end

function sphere_z(longitude,latitude)
    local z = sind(latitude)
    return z
end



segments = {}
function append_surface(
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
            table.insert(segments, {A, B, D})
            table.insert(segments, {A, C, D})
        end
    end

end

function render_segments()
    table.sort(segments, compare_triangles)
    for _, seg in ipairs(segments) do
        local n = #seg; local P, Q, R = seg[1], seg[2], seg[3]

        tex.print('\\draw[line join=round,preaction={fill=yellow}]')
        tex.print(string.format('(%f,%f,%f)--(%f,%f,%f)--(%f,%f,%f)--cycle;',
        P[1],P[2],P[3],Q[1],Q[2],Q[3],R[1],R[2],R[3]
        ))
    end
    segments = {}
end

function cosd(degrees)
    return math.cos(degrees * 3.14159265 / 180)
end

function sind(degrees)
    return math.sin(degrees * 3.14159265 / 180)
end

-- test
-- append_surface(
--     0,720,100,
--     0,360,18,
--     function(u,v) 
--         return (2+cosd(1.5*u))*cosd(u)+0.3*sphere_x(u,1.5*v) 
--     end,
--     function(u,v) 
--         return (2+cosd(1.5*u))*sind(u)+0.3*sphere_y(u,1.5*v)
--     end,
--     function(u,v) return 2*sind(1.5*u)+0.3*sphere_z(u,1.5*v) end
-- )
-- render_segments()
