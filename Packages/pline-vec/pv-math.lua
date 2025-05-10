function cross_product(u,v)
    local x = u[2]*v[3]-u[3]*v[2]
    local y = u[3]*v[1]-u[1]*v[3]
    local z = u[1]*v[2]-u[2]*v[1]
    local result = {x,y,z}
    return result
end

function dot_product(u,v)
    local result = u[1]*v[1] + u[2]*v[2] + u[3]*v[3]
    return result
end

function norm(u)
    local result = math.sqrt((u[1])^2 + (u[2])^2 + (u[3])^2)
    return result
end

function ZYZ_rotation_matrix(angles,vector)
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

function sphere(longitude,latitude)
    local x = (math.cosd(latitude)*math.cosd(longitude))
    local y = (math.cosd(latitude)*math.sind(longitude))
    local z = math.sind(latitude)
    local result = {x,y,z}
    return result
end

function normalize_vector(u,name)
    local norm = norm(u)
    local x = u[1]/norm
    local y = u[2]/norm
    local z = u[3]/norm
    local result = {x,y,z}
    return result
end

function orthogonal_vector(u)
    if (u[1]~=0 and u[2]==0 and u[3]==0) then
        local v = cross_product(u,{0,1,0})
    else
        local v = cross_product(u,{1,0,0})
    end
    result = v
    return result
end