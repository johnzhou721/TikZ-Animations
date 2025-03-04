function cross_product(a, b)
    return {
        a[2] * b[3] - a[3] * b[2],
        a[3] * b[1] - a[1] * b[3],
        a[1] * b[2] - a[2] * b[1]
    }
end
function dot_product(a, b)
    return a[1] * b[1] + a[2] * b[2] + a[3] * b[3]
end


-- Function to find the orthonormal basis vectors for a plane
function orthonormal_basis(normal_vector)
    -- Normalize the normal vector
    local magnitude = math.sqrt(normal_vector[1]^2 + normal_vector[2]^2 + normal_vector[3]^2)
    local n = {normal_vector[1] / magnitude, normal_vector[2] / magnitude, normal_vector[3] / magnitude}
    
    -- Find a vector not parallel to the normal vector
    local non_parallel = (math.abs(n[1]) > 0.9) and {0, 1, 0} or {1, 0, 0}
    
    -- Use the cross product to find a vector perpendicular to the normal vector
    local u = {
        n[2] * non_parallel[3] - n[3] * non_parallel[2],
        n[3] * non_parallel[1] - n[1] * non_parallel[3],
        n[1] * non_parallel[2] - n[2] * non_parallel[1]
    }
    
    -- Normalize the perpendicular vector
    local u_magnitude = math.sqrt(u[1]^2 + u[2]^2 + u[3]^2)
    u = {u[1] / u_magnitude, u[2] / u_magnitude, u[3] / u_magnitude}
    
    -- Find the third vector using the cross product of the normal and u vectors
    local v = {
        n[2] * u[3] - n[3] * u[2],
        n[3] * u[1] - n[1] * u[3],
        n[1] * u[2] - n[2] * u[1]
    }
    
    return u, v
end

-- Function to sort points based on the angle with the centroid using orthonormal basis
function sort_points(points, u, v)
    -- Calculate centroid
    local centroid = {x = 0, y = 0, z = 0}
    for _, point in ipairs(points) do
        centroid.x = centroid.x + point.x
        centroid.y = centroid.y + point.y
        centroid.z = centroid.z + point.z
    end
    centroid.x = centroid.x / #points
    centroid.y = centroid.y / #points
    centroid.z = centroid.z / #points

    -- Sort points by angle
    table.sort(points, function(a, b)
        local ax = (a.x - centroid.x) * u[1] + (a.y - centroid.y) * u[2] + (a.z - centroid.z) * u[3]
        local ay = (a.x - centroid.x) * v[1] + (a.y - centroid.y) * v[2] + (a.z - centroid.z) * v[3]
        local bx = (b.x - centroid.x) * u[1] + (b.y - centroid.y) * u[2] + (b.z - centroid.z) * u[3]
        local by = (b.x - centroid.x) * v[1] + (b.y - centroid.y) * v[2] + (b.z - centroid.z) * v[3]
        local angle_a = math.atan2(ay, ax)
        local angle_b = math.atan2(by, bx)
        return angle_a < angle_b
    end)

    return points
end

-- Function to draw a plane
function get_plane(normal_vector, point_on_plane, xmin, xmax, ymin, ymax, zmin, zmax, thename)
    -- Plane equation: ax + by + cz = d
    local a, b, c = normal_vector[1], normal_vector[2], normal_vector[3]
    local d = a * point_on_plane[1] + b * point_on_plane[2] + c * point_on_plane[3]

    -- Functions to solve for x, y, z in terms of the other coordinates
    local function solve_x(y, z)
        return (d - b * y - c * z) / a
    end

    local function solve_y(x, z)
        return (d - a * x - c * z) / b
    end

    local function solve_z(x, y)
        return (d - a * x - b * y) / c
    end

    -- List to hold the intersections
    local intersections = {}

    -- Calculate intersections with the box edges
    local function add_intersection(x, y, z)
        if x >= xmin and x <= xmax and y >= ymin and y <= ymax and z >= zmin and z <= zmax then
            table.insert(intersections, {x = x, y = y, z = z})
        end
    end

    -- Loop through each face of the box
    for y = ymin, ymax, ymax - ymin do
        for z = zmin, zmax, zmax - zmin do
            add_intersection(solve_x(y, z), y, z)
        end
    end

    for x = xmin, xmax, xmax - xmin do
        for z = zmin, zmax, zmax - zmin do
            add_intersection(x, solve_y(x, z), z)
        end
    end

    for x = xmin, xmax, xmax - xmin do
        for y = ymin, ymax, ymax - ymin do
            add_intersection(x, y, solve_z(x, y))
        end
    end

    -- Find orthonormal basis vectors for the plane
    local u, v = orthonormal_basis(normal_vector)

    -- Sort intersections
    intersections = sort_points(intersections, u, v)

    -- Prepare the TikZ path for the plane outline
    local path = {}
    for _, intersection in ipairs(intersections) do
        table.insert(path, string.format("(%f, %f, %f)", intersection.x, intersection.y, intersection.z))
    end

    thename1 = thename.."a"
    thename2 = thename.."b"

    -- Generate the TikZ code to draw the plane
    if #intersections >= 3 then
        tex.print("\\path[spath/save = "..thename.."]")
        tex.print(table.concat(path, " -- ").." -- cycle;")
    end

    local nx = normal_vector[1]
    local ny = normal_vector[2]
    local nz = normal_vector[3]
    local nl = ((nx)^2 + (ny)^2 + (nz)^2)^(1/2)
    local zpx = nx/nl
    local zpy = ny/nl
    local zpz = nz/nl
    local nd = dot_product({zpx,zpy,zpz}, point_on_plane)
    local ipx = 0
    local ipy = 0
    local ipz = 0
    local ipl = (dot_product({zpx,zpy,zpz}, {ipx, ipy, ipz})-nd)/(nl)^2
    local ipx = ipx-ipl*nx
    local ipy = ipy-ipl*ny
    local ipz = ipz-ipl*nz
    -- a second vector, nonparallel to "zp", called "auxp"
    -- the cross of "auxp" and "ip" is a vector in our plane.
    local auxpx = zpx+2
    local auxpy = zpy
    local auxpz = zpz
    local auxpl = ((auxpx)^2 + (auxpy)^2 + (auxpz)^2)^(1/2)
    local auxpx = auxpx/auxpl
    local auxpy = auxpy/auxpl
    local auxpz = auxpz/auxpl
    -- a vector in the plane, "xp"
    -- will unitize to make a orthonormal basis vector
    -- the cross is always orthogonal to the normal
    local xp = cross_product({zpx,zpy,zpz}, {auxpx,auxpy,auxpz})
    local xpl = ((xp[1])^2 + (xp[2])^2 + (xp[3])^2)^(1/2)
    local xpx = xp[1]/xpl
    local xpy = xp[2]/xpl
    local xpz = xp[3]/xpl
    local yp = cross_product({zpx,zpy,zpz}, {xpx,xpy,xpz})
    local ypl = ((yp[1])^2 + (yp[2])^2 + (yp[3])^2)^(1/2)
    local ypx = yp[1]/ypl
    local ypy = yp[2]/ypl
    local ypz = yp[3]/ypl
    


    local path = {}
    for _, intersection in ipairs(intersections) do
        local apx = intersection.x
        local apy = intersection.y
        local apz = intersection.z
        local vpx = apx-ipx
        local vpy = apy-ipy
        local vpz = apz-ipz
        local bpx = dot_product({vpx,vpy,vpz}, {xpx,xpy,xpz})
        local bpy = dot_product({vpx,vpy,vpz}, {ypx,ypy,ypz})
        table.insert(path, string.format("(%f, %f)", bpx, bpy))
    end
    tex.print("\\neworrenewcommand{\\plineplanepath"..thename.."}{"..table.concat(path, " -- ").." -- cycle;}\n")
    tex.print("\\pgfmathsetmacro{\\plineipx}{"..ipx.."}\n")
    tex.print("\\pgfmathsetmacro{\\plineipy}{"..ipy.."}\n")
    tex.print("\\pgfmathsetmacro{\\plineipz}{"..ipz.."}\n")
    tex.print("\\pgfmathsetmacro{\\plinexpx}{"..xpx.."}\n")
    tex.print("\\pgfmathsetmacro{\\plinexpy}{"..xpy.."}\n")
    tex.print("\\pgfmathsetmacro{\\plinexpz}{"..xpz.."}\n")
    tex.print("\\pgfmathsetmacro{\\plineypx}{"..ypx.."}\n")
    tex.print("\\pgfmathsetmacro{\\plineypy}{"..ypy.."}\n")
    tex.print("\\pgfmathsetmacro{\\plineypz}{"..ypz.."}\n")
    tex.print("\\pgfmathsetmacro{\\plinezpx}{"..zpx.."}\n")
    tex.print("\\pgfmathsetmacro{\\plinezpy}{"..zpy.."}\n")
    tex.print("\\pgfmathsetmacro{\\plinezpz}{"..zpz.."}\n")
    tex.print("\\coordinate (Shift"..thename..") at (\\plineipx,\\plineipy,\\plineipz);\n")
    tex.print("\\coordinate (X"..thename..") at (\\plinexpx,\\plinexpy,\\plinexpz);\n")
    tex.print("\\coordinate (Y"..thename..") at (\\plineypx,\\plineypy,\\plineypz);\n")
    tex.print("\\coordinate (Z"..thename..") at (\\plinezpx,\\plinezpy,\\plinezpz);\n")
    tex.print("\\tikzset{S"..thename.."/.style = {x = {(X"..thename..")}, y = {(Y"..thename..")}, z = {(Z"..thename..")}, shift = {(Shift"..thename..")}, canvas is xy plane at z = 0     }}\n")
    --tex.print("\\scoped[S"..thename.."]\\path[spath/save = "..thename2.."]\\plineplanepath"..thename..";\n")
end
