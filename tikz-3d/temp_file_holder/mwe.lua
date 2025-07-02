function cross(u,v)
    local x = u[2]*v[3]-u[3]*v[2]
    local y = u[3]*v[1]-u[1]*v[3]
    local z = u[1]*v[2]-u[2]*v[1]
    local result = {x,y,z}
    return result
end

function orthogonal_vector(u)
    local v
    if (u[1]~=0 and u[2]==0 and u[3]==0) then
        v = cross(u,{0,1,0})
    else
        v = cross(u,{1,0,0})
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

function get_bounding_box(triangle)
    local P,Q,R = table.unpack(triangle)
    local xmin = math.min(P[1],Q[1],R[1])
    local xmax = math.max(P[1],Q[1],R[1])
    local ymin = math.min(P[2],Q[2],R[2])
    local ymax = math.max(P[2],Q[2],R[2])
    local zmin = math.min(P[3],Q[3],R[3])
    local zmax = math.max(P[3],Q[3],R[3])
    return {
        xmin,xmax
        ,ymin,ymax
        ,zmin,zmax
    }
end

function check_bounding_box_overlap(bounding_box_1,bounding_box_2)
    local xmin1, xmax1, ymin1, ymax1, zmin1, zmax1 = table.unpack(bounding_box_1)
    local xmin2, xmax2, ymin2, ymax2, zmin2, zmax2 = table.unpack(bounding_box_2)

    local x_overlap = xmax1 >= xmin2 and xmax2 >= xmin1
    local y_overlap = ymax1 >= ymin2 and ymax2 >= ymin1
    local z_overlap = zmax1 >= zmin2 and zmax2 >= zmin1

    return x_overlap and y_overlap and z_overlap
end

function get_observer_plane_basis(observer)
    local origin = {0,0,0}
    local basis_i = orthogonal_vector(observer)
    basis_i = normalize(basis_i)
    local basis_j = cross(observer,basis_i)
    basis_j = normalize(basis_j)
    return {origin,basis_i,basis_j}
end

function proj(base_vector,projected_vector)
    local scale = (
        dot(base_vector,projected_vector) / 
        dot(base_vector,base_vector)
    )
    return {base_vector[1]*scale,base_vector[2]*scale,base_vector[3]*scale}
end

function project_point_onto_basis(point,basis)
    local normal = cross(basis[2],basis[3])
    normal = normalize(normal)
    local vector_from_plane = proj(normal,point)
    local result = {
        point[1]-vector_from_plane[1]
        ,point[2]-vector_from_plane[2]
        ,point[3]-vector_from_plane[3]
    }
    return result
end

function is_point_in_triangle(point,triangle)
    local P,Q,R = table.unpack(triangle)
    local cross_PQ = cross(
        addition(Q,scalar_multiplication(P,-1))
        ,addition(point,scalar_multiplication(P,-1))
    )
    local cross_QR = cross(
        addition(R,scalar_multiplication(Q,-1))
        ,addition(point,scalar_multiplication(Q,-1))
    )
    local cross_RP = cross(
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

function get_line(normal_equation1,normal_equation2,boundaries)
    local a1,b1,c1,d1 = table.unpack(normal_equation1)
    local a2,b2,c2,d2 = table.unpack(normal_equation2)
    local xmin,xmax,ymin,ymax,zmin,zmax = table.unpack(boundaries)
    function Lyofx(x)
        return (
            (
                (
                    d2 - 
                    c2 * d1 / c1
                ) - (
                    a2 -
                    c2 * a1 / c1
                ) * x
            ) / (
                b2 -
                c2 * b1 / c1
            )
        )
    end
    function Lzofx(x)
        return (
            (
                (
                    d2 - 
                    b2 * d1 / b1
                ) - (
                    a2 -
                    b2 * a1 / b1
                ) * x
            ) / (
                c2 -
                b2 * c1 / b1
            )
        )
    end
    function Lzofy(y)
        return (
            (
                (
                    d2 - 
                    a2 * d1 / a1
                ) - (
                    b2 -
                    a2 * b1 / a1
                ) * y
            ) / (
                c2 -
                a2 * c1 / a1
            )
        )
    end
    function Lxofy(y)
        return (
            (
                (
                    d2 - 
                    c2 * d1 / c1
                ) - (
                    b2 -
                    c2 * b1 / c1
                ) * y
            ) / (
                a2 -
                c2 * a1 / c1
            )
        )
    end
    function Lyofz(z)
        return (
            (
                (
                    d2 - 
                    a2 * d1 / a1
                ) - (
                    c2 -
                    a2 * c1 / a1
                ) * z
            ) / (
                b2 -
                a2 * b1 / a1
            )
        )
    end
    function Lxofz(z)
        return (
            (
                (
                    d2 - 
                    b2 * d1 / b1
                ) - (
                    c2 -
                    b2 * c1 / b1
                ) * z
            ) / (
                a2 -
                b2 * a1 / b1
            )
        )
    end

    if ~(
        math.abs(b2-c2*b1/c1)<0.0001 or
        math.abs(c2-b2*c1/b1)<0.0001
    ) then
        startx = xmin
        starty = Lyofx(xmin)
        startz = Lzofx(xmin)
        endx = smax
        endy = Lyofx(xmax)
        endz = Lzofx(xmax)
         -- y coord
        if endy>ymax then
            endx = Lxofy(ymax)
            endy = Lyofx(Lxofy(ymax))
            endz = Lzofx(Lxofy(ymax))
        end

        if endy<ymin then
            endx = Lxofy(ymin)
            endy = Lyofx(Lxofy(ymin))
            endz = Lzofx(Lxofy(ymin))
        end

        if starty>ymax then
            startx = Lxofy(ymax)
            starty = Lyofx(Lxofy(ymax))
            startz = Lzofx(Lxofy(ymax))
        end
        
        if starty<ymin then
            startx = Lxofy(ymin)
            starty = Lyofx(Lxofy(ymin))
            startz = Lzofx(Lxofy(ymin))
        end

         -- z coord
        if endz>zmax then
            endx = Lxofz(zmax)
            endy = Lyofx(Lxofz(zmax))
            endz = Lzofx(Lxofz(zmax))
        end
        if endz<zmin then
            endx = Lxofz(zmin)
            endy = Lyofx(Lxofz(zmin))
            endz = Lzofx(Lxofz(zmin))
        end
        if startz>zmax then
            startz = Lxofz(zmax)
            startz = Lyofx(Lxofz(zmax))
            startz = Lzofx(Lxofz(zmax))
        end
        if startz<zmin then
            startz = Lxofz(zmin)
            startz = Lyofx(Lxofz(zmin))
            startz = Lzofx(Lxofz(zmin))
        end
    else
        if ~(
            math.abs(c2-a2*c1/a1)<0.001 or
            math.abs(a2-c2*a1/c1)<0.001
        ) then
            startx = Lxofy(ymin)
            starty = ymin
            startz = Lzofy(ymin)
            endx = Lxofy(ymax)
            endy = ymax
            endz = Lzofy(ymax)

            if endx>xmax then
                endx = Lxofy(Lyofx(xmax))
                endy = Lyofx(xmax) 
                endz = Lzofy(Lyofx(xmax))
            end

            if endx<xmin then
                endx = Lxofy(Lyofx(xmin))
                endy = Lyofx(xmin) 
                endz = Lzofy(Lyofx(xmin))
            end

            if startx>xmax then
                startx = Lxofy(Lyofx(xmax))
                starty = Lyofx(xmax) 
                startz = Lzofy(Lyofx(xmax))
            end

            if startx<xmin then
                startx = Lxofy(Lyofx(xmin))
                starty = Lyofx(xmin) 
                startz = Lzofy(Lyofx(xmin))
            end

            if endz>zmax then
                endx = Lxofy(Lyofz(zmax))
                endy = Lyofz(zmax)
                endz = Lzofy(Lyofz(zmax))
            end

            if endz<zmin then
                endx = Lxofy(Lyofz(zmin))
                endy = Lyofz(zmin)
                endz = Lzofy(Lyofz(zmin))
            end

            if startz>zmax then
                startx = Lxofy(Lyofz(zmax))
                starty = Lyofz(zmax)
                startz = Lzofy(Lyofz(zmax))
            end

            if startz<zmin then
                startx = Lxofy(Lyofz(zmin))
                starty = Lyofz(zmin)
                startz = Lzofy(Lyofz(zmin))
            end
        else
            if ~(
            math.abs(b2-a2*b1/a1)<0.001 or
            math.abs(a2-b2*a1/b1)<0.001 
            ) then
                startx = Lxofz(zmin)
                starty = Lyofz(zmin)
                startz = zmin
                endx = Lxofz(zmax)
                endy = Lyofz(zmax)
                endz = zmax

                if endx>xmax then
                    endx = Lxofz(Lzofx(xmax))
                    endy = Lyofz(Lzofx(xmax))
                    endz = Lzofx(xmax)
                end

                if endx<xmin then
                    endx = Lxofz(Lzofx(xmin))
                    endy = Lyofz(Lzofx(xmin))
                    endz = Lzofx(xmin)
                end

                if endy>ymax then
                    endx = Lxofz(Lzofy(ymax))
                    endy = Lyofz(Lzofy(ymax))
                    endz = Lzofy(ymax)
                end
                if endy<ymin then
                    endx = Lxofz(Lzofy(ymin))
                    endy = Lyofz(Lzofy(ymin))
                    endz = Lzofy(ymin)
                end
                
                
                if startx>xmax then
                    startx = Lxofz(Lzofx(xmax))
                    starty = Lyofz(Lzofx(xmax))
                    startz = Lzofx(xmax)
                end

                if startx<xmin then
                    startx = Lxofz(Lzofx(xmin))
                    starty = Lyofz(Lzofx(xmin))
                    startz = Lzofx(xmin)
                end

                if starty>ymax then
                    startx = Lxofz(Lzofy(ymax))
                    starty = Lyofz(Lzofy(ymax))
                    startz = Lzofy(ymax)
                end
                if starty<ymin then
                    startx = Lxofz(Lzofy(ymin))
                    starty = Lyofz(Lzofy(ymin))
                    startz = Lzofy(ymin)
                end
            end
        end
    end
    point = {startx,starty,startz}
    direction_vector = addition({endx,endy,endz})
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

    local bounding_box_1 = get_bounding_box(triangle_1)
    local bounding_box_2 = get_bounding_box(triangle_2)
    if check_bounding_box_overlap(bounding_box_1,bounding_box_2) then 
        local normal1 = cross(
            addition(
                Q_1
                ,scalar_multiplication(P_1,-1)
            )
            ,addition(
                R_1
                ,scalar_multiplication(P_1,-1)
            )
        )
        local normal2 = cross(
            addition(
                Q_2
                ,scalar_multiplication(P_2,-1)
            )
            ,addition(
                R_2
                ,scalar_multiplication(P_2,-1)
            )
        )
        direction_vector_of_intersection_line = cross(normal1,normal2)
        --point_on_intersection_line = 

    end
    
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
        local normal_1 = cross(
            addition(
                Q_1
                ,scalar_multiplication(P_1,-1)
            )
            ,addition(
                R_1
                ,scalar_multiplication(P_1,-1)
            )
        )
        if dot(normal_1,observer) < 0 then
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
                dot(
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
                dot(
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
                dot(
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
            local normal_1 = cross(
                addition(
                    Q_1
                    ,scalar_multiplication(P_1,-1)
                )
                ,addition(
                    R_1
                    ,scalar_multiplication(P_1,-1)
                )
            )
            if dot(normal_1,observer) < 0 then
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
                    dot(
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
                    dot(
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
                    dot(
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
            local dot_1 = dot(midpoint_1,observer)
            local dot_2 = dot(midpoint_2,observer)
            return dot_1 > dot_2
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

function dot(u,v)
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
