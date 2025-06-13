-- Convert degrees to radians
function deg_to_rad(degrees)
    return degrees * math.pi / 180
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
        local x = math.cosd(elevation)*math.cosd(azimuth)
        local y = math.cosd(elevation)*math.sind(azimuth)
        local z = math.sind(elevation)
        return {x, y, z}
    end

    function SP(x, y, z)
        local sx = x/(1-z)
        local sy = y/(1-z)
        return {sx, sy, 0}
    end

    function ISP(Re, Im)
        local x = 2*(Re)/(1+(Re)^2+(Im)^2)
        local y = 2*(Im)/(1+(Re)^2+(Im)^2)
        local z = (-1+(Re)^2+(Im)^2)/(1+(Re)^2+(Im)^2)
        return {x, y, z}
    end

    elevation = 30
    azimuth = 130

    camera = {
        sphere(azimuth, elevation)[2]
        ,-sphere(azimuth, elevation)[1]
        ,sphere(azimuth, elevation)[3]
    }

    -- Credit: https://tex.stackexchange.com/a/736753/319072
    -- ZYZ rotation matrix transformation
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
    rotated_coords = {rotation,rotation,rotation}
    samples = 36
    for x = -5, 5, (5-(-5))/samples do
        samples = 300
        count = 0
        tex.print("\\typeout{Vertical Lines on Plane Iteration}")
        for y = -5, 5, (5-(-5))/samples do
            count = count + 1

            startx = transformrotmain(ISP(x,y),rotated_coords)[1]
            starty = transformrotmain(ISP(x,y),rotated_coords)[2]
            startz = transformrotmain(ISP(x,y),rotated_coords)[3]

            endx = transformrotmain(ISP(x,y+(5-(-5))/samples),rotated_coords)[1]
            endy = transformrotmain(ISP(x,y+(5-(-5))/samples),rotated_coords)[2]
            endz = transformrotmain(ISP(x,y+(5-(-5))/samples),rotated_coords)[3]

            startx = SP(startx,starty,startz)[1]
            starty = SP(startx,starty,startz)[2]
            startz = SP(startx,starty,startz)[3]

            endx = SP(endx,endy,endz)[1]
            endy = SP(endx,endy,endz)[2]
            endz = SP(endx,endy,endz)[3]

            if (count~=samples and endz<0.999) then
                tex.print(string.format("\\draw[ultra thin] (%f,%f,%f) -- (%f,%f,%f);",startx,starty,startz,endx,endy,endz))
            end
        end
    end
    tex.print("\\typeout{Vertical Lines on Plane Complete}")

    samples = 36
    for y = -5, 5, (5-(-5))/samples do
        samples = 300
        count = 0
        tex.print("\\typeout{Horizontal Lines on Plane Iteration}")
        for x = -5, 5, (5-(-5))/samples do
            count = count + 1

            startx = transformrotmain(ISP(x,y),rotated_coords)[1]
            starty = transformrotmain(ISP(x,y),rotated_coords)[2]
            startz = transformrotmain(ISP(x,y),rotated_coords)[3]

            endx = transformrotmain(ISP(x+(5-(-5))/samples,y),rotated_coords)[1]
            endy = transformrotmain(ISP(x+(5-(-5))/samples,y),rotated_coords)[2]
            endz = transformrotmain(ISP(x+(5-(-5))/samples,y),rotated_coords)[3]
            
            startx = SP(startx,starty,startz)[1]
            starty = SP(startx,starty,startz)[2]
            startz = SP(startx,starty,startz)[3]

            endx = SP(endx,endy,endz)[1]
            endy = SP(endx,endy,endz)[2]
            endz = SP(endx,endy,endz)[3]

            if (count~=samples and endz<0.999) then
                tex.print(string.format("\\draw[ultra thin] (%f,%f,%f) -- (%f,%f,%f);",startx,starty,startz,endx,endy,endz))
            end
        end
    end
    tex.print("\\typeout{Horizontal Lines on Plane Complete}")

    tex.print(string.format("\\fill[white] ({cos(%f)},{sin(%f)}) arc [start angle=%f, end angle={%f-180}, radius=1] -- cycle;",azimuth,azimuth,azimuth,azimuth))
    tex.print("\\fill[tdplot_screen_coords,white] ({cos(0)},{sin(0)}) arc [start angle=0, end angle=180, radius=1] -- cycle;")
    
    samples = 36
    for x = -5, 5, (5-(-5))/samples do
        samples = 300
        count = 0
        tex.print("\\typeout{Vertical Lines on Sphere Iteration}")
        for y = -5, 5, (5-(-5))/samples do
            count = count + 1

            startx = transformrotmain(ISP(x,y),rotated_coords)[1]
            starty = transformrotmain(ISP(x,y),rotated_coords)[2]
            startz = transformrotmain(ISP(x,y),rotated_coords)[3]

            endx = transformrotmain(ISP(x,y+(5-(-5))/samples),rotated_coords)[1]
            endy = transformrotmain(ISP(x,y+(5-(-5))/samples),rotated_coords)[2]
            endz = transformrotmain(ISP(x,y+(5-(-5))/samples),rotated_coords)[3]

            dotproduct = endx*camera[1] + endy*camera[2] + endz*camera[3]

            if (count~=samples and dotproduct>0 and endz>0) then
                tex.print(string.format("\\draw[ultra thin] (%f,%f,%f) -- (%f,%f,%f);",startx,starty,startz,endx,endy,endz))
            end
        end
    end
    tex.print("\\typeout{Vertical Lines on Sphere Complete}")

    samples = 36
    for y = -5, 5, (5-(-5))/samples do
        samples = 300
        count = 0
        tex.print("\\typeout{Horizontal Lines on Sphere Iteration}")
        for x = -5, 5, (5-(-5))/samples do
            count = count + 1

            startx = transformrotmain(ISP(x,y),rotated_coords)[1]
            starty = transformrotmain(ISP(x,y),rotated_coords)[2]
            startz = transformrotmain(ISP(x,y),rotated_coords)[3]

            endx = transformrotmain(ISP(x+(5-(-5))/samples,y),rotated_coords)[1]
            endy = transformrotmain(ISP(x+(5-(-5))/samples,y),rotated_coords)[2]
            endz = transformrotmain(ISP(x+(5-(-5))/samples,y),rotated_coords)[3]
            
            dotproduct = endx*camera[1] + endy*camera[2] + endz*camera[3]

            if (count~=samples and dotproduct>0 and endz>0) then
                tex.print(string.format("\\draw[ultra thin] (%f,%f,%f) -- (%f,%f,%f);",startx,starty,startz,endx,endy,endz))
            end
        end
    end
    tex.print("\\typeout{Horizontal Lines on Sphere Complete}")
end