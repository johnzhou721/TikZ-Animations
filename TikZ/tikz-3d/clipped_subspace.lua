-- clipped_subspace.lua
local mm = require "matrix_math"
local rtc = require "register_tex_cmd"
_ENV = _G
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
    local a            = single_string_expression(hash.a)
    local b            = single_string_expression(hash.b)
    local c            = single_string_expression(hash.c)
    local d            = single_string_expression(hash.d)
    local xmin         = single_string_expression(hash.xmin)
    local xmax         = single_string_expression(hash.xmax)
    local ymin         = single_string_expression(hash.ymin)
    local ymax         = single_string_expression(hash.ymax)
    local zmin         = single_string_expression(hash.zmin)
    local zmax         = single_string_expression(hash.zmax)
    local fill_options = hash.fill_options
    local draw_options = hash.fill_options
    local transform    = single_string_expression(hash.transformation)

    local normal       = {{a,b,c,1}}


    local intersections = {}
    local sorted_intersections = {}
    local function plane(u,v)
        local x = (d-normal[1][2]*u-normal[1][3]*v)/normal[1][1]
        local y = (d-normal[1][1]*u-normal[1][3]*v)/normal[1][2]
        local z = (d-normal[1][1]*u-normal[1][2]*v)/normal[1][3]
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


local function get_line(normal_equation1,normal_equation2,boundaries)
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

    if not (
        math.abs(b2-c2*b1/c1)<0.0001 or
        math.abs(c2-b2*c1/b1)<0.0001
    ) then
        startx = xmin
        starty = Lyofx(xmin)
        startz = Lzofx(xmin)
        endx = xmax
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
        if not (
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
            if not (
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
    direction_vector = addition({endx,endy,endz},scalar_multiplication(point,-1))
end