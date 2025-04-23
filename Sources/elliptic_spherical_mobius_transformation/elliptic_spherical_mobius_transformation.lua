-- Convert degrees to radians
function deg_to_rad(degrees)
    return degrees * 3.14159265 / 180
end

-- Sine function for degrees
function sind(degrees)
    return math.sin(deg_to_rad(degrees))
end

-- Cosine function for degrees
function cosd(degrees)
    return math.cos(deg_to_rad(degrees))
end

function sphere(azimuth, elevation)
    local x = cosd(elevation)*cosd(azimuth)
    local y = cosd(elevation)*sind(azimuth)
    local z = sind(elevation)
    return {x, y, z}
end

function SP(point)
    local sx = point[1]/(1-point[3])
    local sy = point[2]/(1-point[3])
    return {sx, sy, 0}
end

-- Credit: https://tex.stackexchange.com/a/736753/319072
-- ZYZ rotation matrix transformrotmain
function transformrotmain(point, angles)
    local alpha, beta, gamma = angles[1], angles[2], angles[3]
    
    local c1 = cosd(alpha)
    local s1 = sind(alpha)
    local c2 = cosd(beta)
    local s2 = sind(beta)
    local c3 = cosd(gamma)
    local s3 = sind(gamma)
    
    -- ZYZ rotation matrix
    local R = {
        {c1*c2*c3 - s1*s3, -c1*c2*s3 - s1*c3, c1*s2},
        {s1*c2*c3 + c1*s3, -s1*c2*s3 + c1*c3, s1*s2},
        {-s2*c3, s2*s3, c2}
    }
    
    -- Apply rotation: R * point
    local y_new = R[1][1]*point[1] + R[1][2]*point[2] + R[1][3]*point[3]
    local x_new = -(R[2][1]*point[1] + R[2][2]*point[2] + R[2][3]*point[3])
    local z_new = R[3][1]*point[1] + R[3][2]*point[2] + R[3][3]*point[3]
    
    return {x_new, y_new, z_new}
end

function make_tikzpicture(rotation)
    rotated_coords = {0,90,rotation}
    start_longitude = 0
    end_longitude = 360
    samples_longitude = 36
    step_longitude = (end_longitude - start_longitude) / samples_longitude
    for longitude = start_longitude, end_longitude, step_longitude do
        start_latitude = 0
        end_latitude = 360
        samples_latitude = 500
        step_latitude = (end_latitude-start_latitude)/samples_latitude
        count = 0
        tex.print("\\typeout{Test}")
        for latitude = start_latitude, end_latitude, step_latitude do
            count = count + 1

            start_lineoflongitude = transformrotmain(sphere(longitude,latitude),rotated_coords)
            end_lineoflongitude = transformrotmain(sphere(longitude,latitude+step_latitude),rotated_coords)
            start_lineoflatitude = transformrotmain(sphere(latitude,longitude),rotated_coords)
            end_lineoflatitude = transformrotmain(sphere(latitude+step_latitude,longitude),rotated_coords)

            start_longitudeprojection = SP(start_lineoflongitude)
            end_longitudeprojection = SP(end_lineoflongitude)
            start_latitudeprojection = SP(start_lineoflatitude)
            end_latitudeprojection = SP(end_lineoflatitude)

                tex.print(string.format("\\draw[ultra thin] (%f,%f,%f) -- (%f,%f,%f);",start_lineoflongitude[1],start_lineoflongitude[2],start_lineoflongitude[3],end_lineoflongitude[1],end_lineoflongitude[2],end_lineoflongitude[3]))
                tex.print(string.format("\\draw[ultra thin] (%f,%f,%f) -- (%f,%f,%f);",start_lineoflatitude[1],start_lineoflatitude[2],start_lineoflatitude[3],end_lineoflatitude[1],end_lineoflatitude[2],end_lineoflatitude[3]))
            if (count~=samples_latitude and start_lineoflatitude[3]<0.999 and end_lineoflatitude[3]<0.999) then
                tex.print(string.format("\\draw[ultra thin] (%f,%f,%f) -- (%f,%f,%f);",start_latitudeprojection[1],start_latitudeprojection[2],start_latitudeprojection[3],end_latitudeprojection[1],end_latitudeprojection[2],end_latitudeprojection[3]))
            end
            if (count~=samples_latitude and start_lineoflongitude[3]<0.999 and end_lineoflongitude[3]<0.999) then
                tex.print(string.format("\\draw[ultra thin] (%f,%f,%f) -- (%f,%f,%f);",start_longitudeprojection[1],start_longitudeprojection[2],start_longitudeprojection[3],end_longitudeprojection[1],end_longitudeprojection[2],end_longitudeprojection[3]))
            end
        end
    end
end