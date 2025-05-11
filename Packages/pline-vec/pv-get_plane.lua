function plane(u,v)
end

local intersections = {}
local sorted_intersections = {}

function add_intersection(i)
end

function get_plane(
    size,normal,d_value
    ,xmax,xmin,ymax,ymin,zmax,zmin
    ,name
)
    function plane(u,v)
        local x = (d_value-normal[2]*u-normal[3]*v)/normal[1]
        local y = (d_value-normal[1]*u-normal[3]*v)/normal[2]
        local z = (d_value-normal[1]*u-normal[2]*v)/normal[3]
        local result = {x,y,z}
        return result
    end
    for index, value in ipairs(intersections) do
        intersections[index] = nil
    end   
    function add_intersection(i)
        if (
            i[1]>=xmin and i[1]<=xmax and
            i[2]>=ymin and i[2]<=ymax and
            i[3]>=zmin and i[3]<=zmax
        ) then
            table.insert(intersections,{i[1],i[2],i[3]})
        end
    end
    for y = ymin, ymax, ymax-ymin do
        for z = zmin, zmax, zmax-zmin do
            local x = plane(y,z)[1]
            add_intersection({x,y,z})
        end
    end
    for x = xmin, xmax, xmax-xmin do
        for z = zmin, zmax, zmax-zmin do
            local y = plane(x,z)[2]
            add_intersection({x,y,z})
        end
    end
    for x = xmin, xmax, xmax-xmin do
        for y = ymin, ymax, ymax-ymin do
            local z = plane(x,y)[3]
            add_intersection({x,y,z})
        end
    end
    local n = normalize_vector(normal)
    local u = orthogonal_vector(n)
    local u = normalize_vector(u)
    local v = cross_product(n,u)
    for index, value in ipairs(sorted_intersections) do
        sorted_intersections[index] = nil
    end   
    local centroid = {0,0,0}
    local number_of_points = 0
    for index, value in ipairs(intersections) do
        for index, value in ipairs(centroid) do
            centroid[index] = centroid[index] + value
        end
        number_of_points = number_of_points + 1
    end
    local centroid = {
        centroid[1]/number_of_points
        ,centroid[2]/number_of_points
        ,centroid[3]/number_of_points
    }
    for index, value in ipairs(intersections) do
        local ax = dot_product(
            {value[1]-centroid[1]
            ,value[2]-centroid[2]
            ,value[3]-centroid[3]}
            ,{u[1],u[2],u[3]}
        )
        local ay = dot_product(
            {value[1]-centroid[1]
            ,value[2]-centroid[2]
            ,value[3]-centroid[3]}
            ,{v[1],v[2],v[3]}
        )
        local anglea = math.atan2(ay,ax)
        table.insert(
            sorted_intersections
            ,{anglea,value[1],value[2],value[3]}
        )
        table.sort(
            sorted_intersections
            ,function(a, b)
                return a[1] < b[1]
            end
        )
        local path_one = ""
        for index, value in ipairs(sorted_intersections) do
            path_one = string.format(path_one.." (%f,%f,%f) --",value[2],value[3],value[4])
        end
        tex.print("\\path[spath/save = plane"..name.."]"..path_one.."cycle;")
    end 
end