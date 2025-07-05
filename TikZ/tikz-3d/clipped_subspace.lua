-- clipped_subspace.lua
local mm = require "matrix_math"
local rtc = require "register_tex_cmd"
_ENV = _G -- use this to *add* the functions in test
for i,j in pairs(mm) do
  _ENV[i] = j
end


local list_of_planes = {}

local function single_string_expression(str)
    if not str or str == "" then
        return nil
    end
    return load(("return %s"):format(str))()
end

local function append_plane(hash)
    local a            = hash.a
    local b            = hash.b
    local c            = hash.c
    local d            = hash.d
    local normal       = {{single_string_expression(a),single_string_expression(b),single_string_expression(c),1}}
    local d_value      = d
    local xmin         = hash.xmin
    local xmax         = hash.xmax
    local ymin         = hash.ymin
    local ymax         = hash.ymax
    local zmin         = hash.zmin
    local zmax         = hash.zmax
    local fill_options = hash.fill_options
    local draw_options = hash.fill_options
    local transform    = single_string_expression(hash.transformation)

    d_value = single_string_expression(d_value)
    xmin = single_string_expression(xmin)
    xmax = single_string_expression(xmax)
    ymin = single_string_expression(ymin)
    ymax = single_string_expression(ymax)
    zmin = single_string_expression(zmin)
    zmax = single_string_expression(zmax)

    local intersections = {}
    local sorted_intersections = {}
    local function plane(u,v)
        local x = (d_value-normal[1][2]*u-normal[1][3]*v)/normal[1][1]
        local y = (d_value-normal[1][1]*u-normal[1][3]*v)/normal[1][2]
        local z = (d_value-normal[1][1]*u-normal[1][2]*v)/normal[1][3]
        local result = {{x,y,z,1}}
        return result
    end
    local function add_intersection(i)
        if (
            i[1][1]>=xmin and i[1][1]<=xmax and
            i[1][2]>=ymin and i[1][2]<=ymax and
            i[1][3]>=zmin and i[1][3]<=zmax
        ) then
            table.insert(intersections,{{i[1][1],i[1][2],i[1][3],1}})
        end
    end
    if normal[1][1]~=0 then
        for y = ymin, ymax, ymax-ymin do
            for z = zmin, zmax, zmax-zmin do
                local x = plane(y,z)[1][1]
                add_intersection({{x,y,z,1}})
            end
        end
    end
    if normal[1][2]~=0 then
        for x = xmin, xmax, xmax-xmin do
            for z = zmin, zmax, zmax-zmin do
                local y = plane(x,z)[1][2]
                add_intersection({{x,y,z,1}})
            end
        end
    end
    if normal[1][3]~=0 then
        for x = xmin, xmax, xmax-xmin do
            for y = ymin, ymax, ymax-ymin do
                local z = plane(x,y)[1][3]
                add_intersection({{x,y,z,1}})
            end
        end
    end
    local n = normalize(normal)
    local u = orthogonal_vector(n)
    local u = normalize(u)
    local v = cross_product(n,u)
    local centroid = {{0,0,0,1}}
    local number_of_points = 0
    for index, value in ipairs(intersections) do
        centroid[1][1] = centroid[1][1]+value[1][1]
        centroid[1][2] = centroid[1][2]+value[1][2]
        centroid[1][3] = centroid[1][3]+value[1][3]
        number_of_points = number_of_points + 1
    end
    local centroid = {{
        centroid[1][1]/number_of_points
        ,centroid[1][2]/number_of_points
        ,centroid[1][3]/number_of_points
        ,1
    }}
    for index, value in ipairs(intersections) do
        local ax = dot_product(
            {{
                value[1][1]-centroid[1][1]
                ,value[1][2]-centroid[1][2]
                ,value[1][3]-centroid[1][3]
                ,1
            }},{{u[1][1],u[1][2],u[1][3],1}}
        )
        local ay = dot_product(
            {{
                value[1][1]-centroid[1][1]
                ,value[1][2]-centroid[1][2]
                ,value[1][3]-centroid[1][3]
                ,1
            }},{{v[1][1],v[1][2],v[1][3],1}}
        )
        local anglea = atan2(ay,ax)
        table.insert(
            sorted_intersections
            ,{angle = anglea, point = {{value[1][1],value[1][2],value[1][3],1}}, draw_options = draw_options, fill_options = fill_options}
        )
    end 
    table.sort(
        sorted_intersections
        ,function(a, b)
            return a.angle < b.angle
        end
    )
    local result = { points = {}, draw_options = draw_options, fill_options = fill_options }
    for i, plane in ipairs(sorted_intersections) do 
        table.insert(result.points,plane.point)
    end
    for i, point in ipairs(result.points) do
        result.points[i] = matrix_multiply(result.points[i],transform)
    end
    table.insert(list_of_planes,result)
end

local function render_planes()
    for i, plane in ipairs(list_of_planes) do
        tex.sprint(("\\draw[preaction={%s},postaction={%s}]"):format(plane.fill_options,plane.draw_options))
        for j, point in ipairs(plane.points) do
            local P = point
            tex.sprint((" (%f,%f) --"):format(P[1][1],P[1][2]))
        end
        tex.sprint(" cycle;")
    end
    list_of_planes = {}
end

rtc.register_tex_cmd(
    "appendplane", function()
    append_plane{
        a              = token.get_macro("tikz@td@cs@p@a"),
        b              = token.get_macro("tikz@td@cs@p@b"),
        c              = token.get_macro("tikz@td@cs@p@c"),
        d              = token.get_macro("tikz@td@cs@p@d"),
        xmin           = token.get_macro("tikz@td@cs@xmin"),
        xmax           = token.get_macro("tikz@td@cs@xmax"),
        ymin           = token.get_macro("tikz@td@cs@ymin"),
        ymax           = token.get_macro("tikz@td@cs@ymax"),
        zmin           = token.get_macro("tikz@td@cs@zmin"),
        zmax           = token.get_macro("tikz@td@cs@zmax"),
        fill_options   = token.get_macro("tikz@td@cs@p@filloptions"),
        draw_options   = token.get_macro("tikz@td@cs@p@drawoptions"),
        transformation = token.get_macro("tikz@td@cs@transformation")
    } end,
    { }
)

rtc.register_tex_cmd(
    "renderplanes", function()
    render_planes() end,
    { }
)
