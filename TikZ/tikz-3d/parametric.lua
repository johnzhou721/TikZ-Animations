-- parametric.lua
local mm = require "matrix_math"
local rtc = require "register_tex_cmd"
local ss = require "segment_sorting"
_ENV = _G -- use this to *add* the functions in test
for i,j in pairs(mm,math) do
  _ENV[i] = j
end

local segments = {}
local observer_dir = { { 0, 0, -1, 1} }
local observer_pos = { { 0, 0, 0, 1} }

local function single_string_expression(str)
    if not str or str == "" then
        return nil
    end
    return load(("return %s"):format(str))()
end

local function append_curve(hash)
    local u_start        = hash.u_start
    local u_stop         = hash.u_stop
    local u_samples      = hash.u_samples
    local x              = hash.x
    local y              = hash.y
    local z              = hash.z
    local draw_options   = hash.draw_options
    local name           = hash.name
    local transformation = hash.transformation

    local function single_string_function(str)
        if not str or str == "" then
            return nil
        end
        return load(("return function(u) return %s end"):format(str))()
    end

    x = single_string_function(x)
    y = single_string_function(y)
    z = single_string_function(z)

    u_start = single_string_expression(u_start)
    u_stop = single_string_expression(u_stop)
    u_samples = single_string_expression(u_samples)
    transformation = single_string_expression(transformation)

    local u_step = (u_stop - u_start) / (u_samples - 1)

    local function parametric_curve(u)
        return { x(u), y(u), z(u), 1 }
    end

    for i = 0, u_samples - 2 do
        local u = u_start + i * u_step
        local A = parametric_curve(u)
        local B = parametric_curve(u+u_step)
        local the_segment = matrix_multiply({ A, B }, transformation)
        table.insert(
            segments, 
            { 
                segment = the_segment, 
                draw_options = draw_options, 
                name = name 
            }
        )
    end
end

local function append_surface(hash)
    local u_start        = hash.u_start
    local u_stop         = hash.u_stop
    local u_samples      = hash.u_samples
    local v_start        = hash.v_start
    local v_stop         = hash.v_stop
    local v_samples      = hash.v_samples
    local x              = hash.x
    local y              = hash.y
    local z              = hash.z
    local draw_options   = hash.draw_options
    local fill_options   = hash.fill_options
    local name           = hash.name
    local transformation = hash.transformation

    local function double_string_function(str)
        if not str or str == "" then
            return nil
        end
        return load(("return function(u,v) return %s end"):format(str))()
    end

    x = double_string_function(x)
    y = double_string_function(y)
    z = double_string_function(z)

    u_start = single_string_expression(u_start)
    u_stop = single_string_expression(u_stop)
    u_samples = single_string_expression(u_samples)
    v_start = single_string_expression(v_start)
    v_stop = single_string_expression(v_stop)
    v_samples = single_string_expression(v_samples)
    transformation = single_string_expression(transformation)

    local u_step = (u_stop - u_start) / (u_samples - 1)
    local v_step = (v_stop - v_start) / (v_samples - 1)

    local function parametric_surface(u, v)
        return { x(u,v), y(u,v), z(u,v), 1 }
    end

    for i = 0, u_samples - 2 do
        local u = u_start + i * u_step
        for j = 0, v_samples - 2 do
            local v = v_start + j * v_step
            local A = parametric_surface(u, v)
            local B = parametric_surface(u + u_step, v)
            local C = parametric_surface(u, v + v_step)
            local D = parametric_surface(u + u_step, v + v_step)
            local the_segment1 = matrix_multiply({ A, B, D },transformation)
            local the_segment2 = matrix_multiply({ A, C, D },transformation)
            table.insert(
                segments, 
                { 
                    segment      = the_segment1, 
                    draw_options = draw_options,
                    fill_options = fill_options, 
                    name         = name 
                }
            )
            table.insert(
                segments, 
                { 
                    segment      = the_segment2, 
                    draw_options = draw_options,
                    fill_options = fill_options, 
                    name         = name 
                }
            )
        end
    end
end

local function render_segments()
    table.sort(segments,ss.compare_triangles)
    for _, segment in ipairs(segments) do
        if #segment.segment == 2 then
            local S, E = segment.segment[1], segment.segment[2]
            local Sx, Sy = S[1], S[2]
            local Ex, Ey = E[1], E[2]
            local options = segment.draw_options
            local abs = math.abs 
            if (abs(Sx)<100 and abs(Sy)<100 and abs(Ex)<100 and abs(Ey)<100) then
                tex.sprint(
                    string.format(
                        "\\draw[%s] (%f,%f) -- (%f,%f);"
                        ,options,Sx, Sy, Ex, Ey
                    )
                )
            end
        elseif #segment.segment == 3 then
            local P, Q, R = segment.segment[1], segment.segment[2], segment.segment[3]
            local Px, Py = P[1], P[2]
            local Qx, Qy = Q[1], Q[2]
            local Rx, Ry = R[1], R[2]
            if (
                abs(Px)<100 and 
                abs(Py)<100 and 
                abs(Qx)<100 and 
                abs(Qy)<100 and
                abs(Rx)<100 and 
                abs(Ry)<100
            ) then
                tex.sprint(
                    string.format(
                        "\\path[preaction = {%s},postaction = {%s}] (%f,%f) -- (%f,%f) -- (%f,%f) -- cycle;",
                        segment.fill_options,segment.draw_options
                        ,Px,Py,Qx,Qy,Rx,Ry
                    )
                )
            end
        elseif #segment.segment > 3 then
            local path = {}
            local include = true
            local abs = math.abs
            for _, P in ipairs(segment.segment) do
                local x, y = P[1], P[2]
                if abs(x) >= 100 or abs(y) >= 100 then
                    include = false
                    break
                end
                table.insert(path, string.format("(%f,%f)", x, y))
            end
            if include then
                tex.sprint(
                    string.format(
                        "\\path[preaction={%s},postaction={%s}] %s -- cycle;",
                        segment.fill_options or "",
                        segment.draw_options or "",
                        table.concat(path, " -- ")
                    )
                )
            end
        end
    end
    segments = {}
end


rtc.register_tex_cmd(
    "appendcurve", function()
    append_curve{
        u_start        = token.get_macro("tikz@td@p@c@umin"),
        u_stop         = token.get_macro("tikz@td@p@c@umax"),
        u_samples      = token.get_macro("tikz@td@p@c@usamples"),
        x              = token.get_macro("tikz@td@p@c@x"),
        y              = token.get_macro("tikz@td@p@c@y"),
        z              = token.get_macro("tikz@td@p@c@z"),
        draw_options   = token.get_macro("tikz@td@p@c@drawoptions"),
        name           = token.get_macro("tikz@td@p@c@name"),
        transformation = token.get_macro("tikz@td@p@c@transformation")
    } end,
    { }
)

rtc.register_tex_cmd(
    "appendsurface", function()
    append_surface{
        u_start        = token.get_macro("tikz@td@p@surf@umin"),
        u_stop         = token.get_macro("tikz@td@p@surf@umax"),
        u_samples      = token.get_macro("tikz@td@p@surf@usamples"),
        v_start        = token.get_macro("tikz@td@p@surf@vmin"),
        v_stop         = token.get_macro("tikz@td@p@surf@vmax"),
        v_samples      = token.get_macro("tikz@td@p@surf@vsamples"),
        x              = token.get_macro("tikz@td@p@surf@x"),
        y              = token.get_macro("tikz@td@p@surf@y"),
        z              = token.get_macro("tikz@td@p@surf@z"),
        draw_options   = token.get_macro("tikz@td@p@surf@drawoptions"),
        fill_options   = token.get_macro("tikz@td@p@surf@filloptions"),
        name           = token.get_macro("tikz@td@p@surf@name"),
        transformation = token.get_macro("tikz@td@p@surf@transformation")
    } end,
    { }
)

rtc.register_tex_cmd("rendersegments", function() render_segments() end, { })

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
    local result = { segment = {}, draw_options = draw_options, fill_options = fill_options }
    for i, plane in ipairs(sorted_intersections) do 
        table.insert(result.segment,plane.point)
    end
    for i, point in ipairs(result.segment) do
        result.segment[i] = matrix_multiply(result.segment[i],transform)[1]
    end
    table.insert(segments,result)
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