function pv_sign(number)
    if number >= 0 then return "positive"
    return "negative"
end
function pv_orthogonal_vector_projection(base_vector,projected_vector)
    local scale = (
        pv_dot_product(base_vector,projected_vector) / 
        pv_dot_product(base_vector,base_vector)
    )
    return {base_vector[1]*scale,base_vector[2]*scale,base_vector[3]*scale}
end
function pv_scalar_multiplication(vector,scalar)
    return {
        vector[1] * scalar
        ,vector[2] * scalar
        ,vector[3] * scalar
    }
end
function pv_addition(vector1,vector2)
    return = {
        vector1[1]+vector2[1]
        ,vector1[2]+vector2[2]
        ,vector1[3]+vector2[3]
    }
end
function pv_cross_product(u,v)
    local x = u[2]*v[3]-u[3]*v[2]
    local y = u[3]*v[1]-u[1]*v[3]
    local z = u[1]*v[2]-u[2]*v[1]
    local result = {x,y,z}
    return result
end

function pv_midpoint(triangle)
    local P,Q,R = table.unpack(triangle)
    local x = (P[1]+Q[1]+R[1])/3
    local y = (P[2]+Q[2]+R[2])/3
    local z = (P[3]+Q[3]+R[3])/3
    return {x,y,z}
end

function pv_signed_distance_to_plane(point,basis)
    O,v1,v2 = table.unpack(basis)
end

function pv_cross_product_x(u,v)
    local x = u[2]*v[3]-u[3]*v[2]
    return x
end

function pv_cross_product_y(u,v)
    local y = u[3]*v[1]-u[1]*v[3]
    return y
end

function pv_cross_product_z(u,v)
    local z = u[1]*v[2]-u[2]*v[1]
    return z
end

function pv_cross_product_x_tex(u,v)
    local x = u[2]*v[3]-u[3]*v[2]
    tex.print(
        string.format(
            "\\pgfmathparse{%f}"
            ,x
        )
    )
end

function pv_cross_product_y_tex(u,v)
    local y = u[3]*v[1]-u[1]*v[3]
    tex.print(
        string.format(
            "\\pgfmathparse{%f}"
            ,y
        )
    )
end

function pv_cross_product_z_tex(u,v)
    local z = u[1]*v[2]-u[2]*v[1]
    tex.print(
        string.format(
            "\\pgfmathparse{%f}"
            ,z
        )
    )
end

function pv_dot_product(u,v)
    local result = u[1]*v[1] + u[2]*v[2] + u[3]*v[3]
    return result
end

function pv_dot_product_tex(u,v)
    local result = u[1]*v[1] + u[2]*v[2] + u[3]*v[3]
    tex.print(
        string.format(
            "\\pgfmathparse{%f}"
            ,result
        )
    )
end

function pv_norm(u)
    local result = math.sqrt((u[1])^2 + (u[2])^2 + (u[3])^2)
    return result
end

function pv_norm_tex(u)
    local result = math.sqrt((u[1])^2 + (u[2])^2 + (u[3])^2)
    tex.print(
        string.format(
            "\\pgfmathparse{%f}"
            ,result
        )
    )
end

function pv_ZYZ_rotation_matrix(angles,vector)
    local c1 = math.cosd(angles[1])
    local c2 = math.cosd(angles[2])
    local c3 = math.cosd(angles[3])
    local s1 = math.sind(angles[1])
    local s2 = math.sind(angles[2])
    local s3 = math.sind(angles[3])
    local x = (
        (c1*c2*c3-s1*s3)*vector[1] +
        (-c1*c2*s3-s1*c3)*vector[2] +
        c1*s2*vector[3]
    )
    local y = (
        (s1*c2*c3+c1*s3)*vector[1] +
        (-s1*c2*s3+c1*c3)*vector[2] +
        s1*s2*vector[3]
    )
    local z = (
        -s2*c3*vector[1] +
        s2*s3*vector[2] +
        c2*vector[3]
    )
    local result = {x,y,z}
    return result
end

function pv_ZYZ_rotation_matrix_x(angles,vector)
    local c1 = math.cosd(angles[1])
    local c2 = math.cosd(angles[2])
    local c3 = math.cosd(angles[3])
    local s1 = math.sind(angles[1])
    local s2 = math.sind(angles[2])
    local s3 = math.sind(angles[3])
    local x = (
        (c1*c2*c3-s1*s3)*vector[1] +
        (-c1*c2*s3-s1*c3)*vector[2] +
        c1*s2*vector[3]
    )
    local result = x
    return result
end

function pv_ZYZ_rotation_matrix_y(angles,vector)
    local c1 = math.cosd(angles[1])
    local c2 = math.cosd(angles[2])
    local c3 = math.cosd(angles[3])
    local s1 = math.sind(angles[1])
    local s2 = math.sind(angles[2])
    local s3 = math.sind(angles[3])
    local y = (
        (s1*c2*c3+c1*s3)*vector[1] +
        (-s1*c2*s3+c1*c3)*vector[2] +
        s1*s2*vector[3]
    )
    local result = y
    return result
end

function pv_ZYZ_rotation_matrix_z(angles,vector)
    local c1 = math.cosd(angles[1])
    local c2 = math.cosd(angles[2])
    local c3 = math.cosd(angles[3])
    local s1 = math.sind(angles[1])
    local s2 = math.sind(angles[2])
    local s3 = math.sind(angles[3])
    local z = (
        -s2*c3*vector[1] +
        s2*s3*vector[2] +
        c2*vector[3]
    )
    local result = z
    return result
end

function pv_ZYZ_rotation_matrix_x_tex(angles,vector)
    local c1 = math.cosd(angles[1])
    local c2 = math.cosd(angles[2])
    local c3 = math.cosd(angles[3])
    local s1 = math.sind(angles[1])
    local s2 = math.sind(angles[2])
    local s3 = math.sind(angles[3])
    local x = (
        (c1*c2*c3-s1*s3)*vector[1] +
        (-c1*c2*s3-s1*c3)*vector[2] +
        c1*s2*vector[3]
    )
    tex.print(
        string.format(
            "\\pgfmathparse{%f}"
            ,x
        )
    )
end

function pv_ZYZ_rotation_matrix_y_tex(angles,vector)
    local c1 = math.cosd(angles[1])
    local c2 = math.cosd(angles[2])
    local c3 = math.cosd(angles[3])
    local s1 = math.sind(angles[1])
    local s2 = math.sind(angles[2])
    local s3 = math.sind(angles[3])
    local y = (
        (s1*c2*c3+c1*s3)*vector[1] +
        (-s1*c2*s3+c1*c3)*vector[2] +
        s1*s2*vector[3]
    )
    tex.print(
        string.format(
            "\\pgfmathparse{%f}"
            ,y
        )
    )
end

function pv_ZYZ_rotation_matrix_z_tex(angles,vector)
    local c1 = math.cosd(angles[1])
    local c2 = math.cosd(angles[2])
    local c3 = math.cosd(angles[3])
    local s1 = math.sind(angles[1])
    local s2 = math.sind(angles[2])
    local s3 = math.sind(angles[3])
    local z = (
        -s2*c3*vector[1] +
        s2*s3*vector[2] +
        c2*vector[3]
    )
    tex.print(
        string.format(
            "\\pgfmathparse{%f}"
            ,z
        )
    )
end

function pv_sphere(longitude,latitude)
    local x = (math.cosd(latitude)*math.cosd(longitude))
    local y = (math.cosd(latitude)*math.sind(longitude))
    local z = math.sind(latitude)
    local result = {x,y,z}
    return result
end

function pv_sphere_x(longitude,latitude)
    local x = (math.cosd(latitude)*math.cosd(longitude))
    return x
end

function pv_sphere_y(longitude,latitude)
    local y = (math.cosd(latitude)*math.sind(longitude))
    return y
end

function pv_sphere_z(longitude,latitude)
    local z = math.sind(latitude)
    return z
end

function pv_sphere_x_tex(longitude,latitude)
    local x = (math.cosd(latitude)*math.cosd(longitude))
    tex.print(
        string.format(
            "\\pgfmathparse{%f}"
            ,x
        )
    )
end

function pv_sphere_y_tex(longitude,latitude)
    local y = (math.cosd(latitude)*math.sind(longitude))
    tex.print(
        string.format(
            "\\pgfmathparse{%f}"
            ,y
        )
    )
end

function pv_sphere_z_tex(longitude,latitude)
    local z = (math.sind(latitude))
    tex.print(
        string.format(
            "\\pgfmathparse{%f}"
            ,z
        )
    )
end

function pv_normalize_vector(u)
    local norm = pv_norm(u)
    local x = u[1]/norm
    local y = u[2]/norm
    local z = u[3]/norm
    local result = {x,y,z}
    return result
end

function pv_normalize_vector(u)
    local norm = pv_norm(u)
    local x = u[1]/norm
    local y = u[2]/norm
    local z = u[3]/norm
    local result = {x,y,z}
    return result
end

function pv_orthogonal_vector(u)
    local v
    if (u[1]~=0 and u[2]==0 and u[3]==0) then
        v = pv_cross_product(u,{0,1,0})
    else
        v = pv_cross_product(u,{1,0,0})
    end
    result = v
    return result
end

function pv_average(a,b,c)
    local x = (a[1] + b[1] + c[1])/3
    local y = (a[2] + b[2] + c[2])/3
    local z = (a[3] + b[3] + c[3])/3
    local result = {x,y,z}
    return result
end

function pv_average2(a,b)
    local x = (a[1] + b[1])/2
    local y = (a[2] + b[2])/2
    local z = (a[3] + b[3])/2
    local result = {x,y,z}
    return result
end

function pv_difference(u,v)
    local x = u[1]-v[1]
    local y = u[2]-v[2]
    local z = u[3]-v[3]
    local result = {x,y,z}
    return result
end