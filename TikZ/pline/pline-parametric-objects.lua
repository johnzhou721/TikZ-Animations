-- pline-parametric-objects.lua
local mm = require "pline-matrix-math"
local rtc = require "pline-register-tex-cmd"
local ENV_ = {}
for k, v in pairs(_G) do ENV_[k] = v end
for k, v in pairs(mm) do ENV_[k] = v end
for k, v in pairs(math) do ENV_[k] = v end

local segments = {}
local observer_dir = { { 0, 0, -1, 1} }
local observer_pos = { { 0, 0, 0, 1} }

local function single_string_expression(str)
    return load(("return %s"):format(str), "expression", "t", ENV_)()
end

local function single_string_function(str)
    return load(("return function(u) return %s end"):format(str), "expression", "t", ENV_)()
end

local function double_string_function(str)
    return load(("return function(u,v) return %s end"):format(str), "expression", "t", ENV_)()
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

    x = single_string_function(x)
    y = single_string_function(y)
    z = single_string_function(z)

    u_start = single_string_expression(u_start)
    u_stop = single_string_expression(u_stop)
    u_samples = single_string_expression(u_samples)
    transformation = single_string_expression(transformation)

    local u_step = (u_stop - u_start) / (u_samples - 1)

    local function parametric_curve(u)
        return { { x(u), y(u), z(u), 1 } }
    end

    for i = 0, u_samples - 2 do
        local u = u_start + i * u_step
        local A = parametric_curve(u)
        local B = parametric_curve(u+u_step)
        local the_segment = mm.matrix_multiply({ A[1], B[1] }, transformation)
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
            local the_segment1 = mm.matrix_multiply({ A, B, D },transformation)
            local the_segment2 = mm.matrix_multiply({ A, C, D },transformation)
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

local function is_point_in_triangle(point,triangle)
    local P,Q,R = table.unpack(triangle)
    P,Q,R = {P},{Q},{R}
    local cross_PQ = mm.cross_product(
        mm.matrix_subtract(Q,P)
        ,point
    )
    local cross_QR = mm.cross_product(
        mm.matrix_subtract(R,Q)
        ,point
    )
    local cross_RP = mm.cross_product(
        mm.matrix_subtract(P,R)
        ,point
    )
    local sign_1 = mm.sign(cross_PQ[1][1])
    local sign_2 = mm.sign(cross_QR[1][1])
    local sign_3 = mm.sign(cross_RP[1][1])
    local sign_4 = mm.sign(cross_PQ[1][2])
    local sign_5 = mm.sign(cross_QR[1][2])
    local sign_6 = mm.sign(cross_RP[1][2])
    local sign_7 = mm.sign(cross_PQ[1][3])
    local sign_8 = mm.sign(cross_QR[1][3])
    local sign_9 = mm.sign(cross_RP[1][3])
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

local function compare_triangles(triangle_1,triangle_2)
    -- 1) if *either* is a 2‐point line/curve (#==3), depth‐sort by midpoint along observer
    if #triangle_1.segment == 2 or #triangle_2.segment == 2 then
        local function depth_mid(seg)
            if #seg == 2 then
                -- line/curve segment: midpoint of S, E
                local S, E = seg[1], seg[2]
                local mid = {{
                    (S[1] + E[1]) / 2,
                    (S[2] + E[2]) / 2,
                    (S[3] + E[3]) / 2,
                    1
                }}
                return mm.dot_product(mid, observer_dir)
            else
                -- triangle: centroid of P, Q, R
                local P, Q, R = seg[1], seg[2], seg[3]
                local cent = {{
                    (P[1] + Q[1] + R[1]) / 3,
                    (P[2] + Q[2] + R[2]) / 3,
                    (P[3] + Q[3] + R[3]) / 3,
                    1
                }}
                return mm.dot_product(cent, observer_dir)
            end
        end
        local a = depth_mid(triangle_1.segment)
        local b = depth_mid(triangle_2.segment)
        return a > b
    end


    if #triangle_1.segment > 3 or #triangle_2.segment > 3 then
        local function depth_mid(segment)
            local x, y, z = 0, 0, 0
            local n = #segment
            for i = 1, n do
                local pt = segment[i]
                x = x + pt[1]
                y = y + pt[2]
                z = z + pt[3]
            end
            local centroid = {{x / n, y / n, z / n, 1}}
            return mm.dot_product(centroid, observer_dir)
        end
        return depth_mid(triangle_1.segment) > depth_mid(triangle_2.segment)
    end
    ---
    local P_1, Q_1, R_1 = table.unpack(triangle_1.segment)
    local P_2, Q_2, R_2 = table.unpack(triangle_2.segment)
    P_1, Q_1, R_1 = {P_1}, {Q_1}, {R_1}
    P_2, Q_2, R_2 = {P_2}, {Q_2}, {R_2}


    local observer_basis = mm.get_observer_plane_basis(observer_dir)
    local P_1_projection = mm.project_point_onto_basis(P_1,observer_basis)
    local Q_1_projection = mm.project_point_onto_basis(Q_1,observer_basis)
    local R_1_projection = mm.project_point_onto_basis(R_1,observer_basis)
    local P_2_projection = mm.project_point_onto_basis(P_2,observer_basis)
    local Q_2_projection = mm.project_point_onto_basis(Q_2,observer_basis)
    local R_2_projection = mm.project_point_onto_basis(R_2,observer_basis)
    -- compare to triangle 1
    local P_test = is_point_in_triangle(P_2_projection,{P_1_projection[1],Q_1_projection[1],R_1_projection[1]})
    local Q_test = is_point_in_triangle(Q_2_projection,{P_1_projection[1],Q_1_projection[1],R_1_projection[1]})
    local R_test = is_point_in_triangle(R_2_projection,{P_1_projection[1],Q_1_projection[1],R_1_projection[1]})
    if (P_test or Q_test or R_test) then
        local test
        if P_test then
            test = "P"
        else
            if Q_test then
                test = "Q"
            else
                test = "R"
            end
        end
        local normal_1 = mm.cross_product(
            mm.matrix_subtract(Q_1,P_1)
            ,mm.matrix_subtract(R_1,P_1)
        )
        if mm.dot_product(normal_1,observer_dir) < 1 then
            normal_1 = mm.matrix_scale(-1,normal_1)
        end
        local signed_distance_to_plane
        if test == "P" then
            signed_distance_to_plane = mm.norm(
                mm.matrix_add(
                    P_2
                    ,mm.matrix_scale(-1,P_2_projection)
                )
            )
            if (
                mm.dot_product(
                    mm.matrix_subtract(P_2,P_2_projection)
                    ,normal_1
                ) < 1
            ) then 
                signed_distance_to_plane = -signed_distance_to_plane
            end
            if mm.sign(signed_distance_to_plane) == "positive" then
                return true
            else
                return false
            end
        end
        if test == "Q" then
            signed_distance_to_plane = mm.norm(
                mm.matrix_subtract(Q_2,Q_2_projection)
            )
            if (
                mm.dot_product(
                    mm.matrix_subtract(Q_2,Q_2_projection)
                    ,normal_1
                ) < 0
            ) then 
                signed_distance_to_plane = -signed_distance_to_plane
            end
            if mm.sign(signed_distance_to_plane) == "positive" then
                return true
            else
                return false
            end
        end
        if test == "R" then
            signed_distance_to_plane = mm.norm(
                mm.matrix_subtract(R_2,R_2_projection)
            )
            if (
                mm.dot_product(
                    mm.matrix_subtract(R_2,R_2_projection)
                    ,normal_1
                ) < 0
            ) then 
                signed_distance_to_plane = -signed_distance_to_plane
            end
            if mm.sign(signed_distance_to_plane) == "positive" then
                return true
            else
                return false
            end
        end
    else
        local midpoint_1 = mm.midpoint({P_1[1],Q_1[1],R_1[1]})
        local midpoint_2 = mm.midpoint({P_2[1],Q_2[1],R_2[1]})
        local dot_product_1 = mm.dot_product(midpoint_1,observer_dir)
        local dot_product_2 = mm.dot_product(midpoint_2,observer_dir)
        return dot_product_1 > dot_product_2
    end
    return false -- test
end

local function render_segments()
    table.sort(segments, compare_triangles)

    for _, segment in ipairs(segments) do
        local pts = segment.segment
        local skip = false

        -- check bounding box for every point
        for _, P in ipairs(pts) do
            if math.abs(P[1]) > 100 or math.abs(P[2]) > 100 then
                skip = true
                break
            end
        end

        if not skip then
            if #pts == 2 then
                -- draw a line segment
                local S, E = pts[1], pts[2]
                tex.sprint(string.format(
                    "\\draw[%s] (%f,%f) -- (%f,%f);",
                    segment.draw_options, S[1], S[2], E[1], E[2]
                ))

            elseif #pts == 3 then
                -- draw a filled triangle
                local P, Q, R = pts[1], pts[2], pts[3]
                tex.sprint(string.format(
                    "\\path[preaction={%s},postaction={%s}] (%f,%f) -- (%f,%f) -- (%f,%f) -- cycle;",
                    segment.fill_options, segment.draw_options,
                    P[1], P[2], Q[1], Q[2], R[1], R[2]
                ))

            elseif #pts > 3 then
                -- draw a general polygon
                local path = {}
                for _, P in ipairs(pts) do
                    table.insert(path, string.format("(%f,%f)", P[1], P[2]))
                end
                tex.sprint(string.format(
                    "\\path[preaction={%s},postaction={%s}] %s -- cycle;",
                    segment.fill_options or "", segment.draw_options or "",
                    table.concat(path, " -- ")
                ))
            end
        end
    end

    -- clear for next frame
    segments = {}
end



rtc.register_tex_cmd(
    "appendcurve",
    function()
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
        } 
    end,
    { }
)

rtc.register_tex_cmd(
    "appendsurface", 
    function()
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
        } 
    end,
    { }
)

rtc.register_tex_cmd("rendersegments", function() render_segments() end, { })

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
    local draw_options = hash.draw_options
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
    local n = mm.normalize(normal)
    local u = mm.orthogonal_vector(n)
    local u = mm.normalize(u)
    local v = mm.cross_product(n,u)
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
        local ax = mm.dot_product(
            {{
                value[1][1]-centroid[1][1]
                ,value[1][2]-centroid[1][2]
                ,value[1][3]-centroid[1][3]
                ,1
            }},{{u[1][1],u[1][2],u[1][3],1}}
        )
        local ay = mm.dot_product(
            {{
                value[1][1]-centroid[1][1]
                ,value[1][2]-centroid[1][2]
                ,value[1][3]-centroid[1][3]
                ,1
            }},{{v[1][1],v[1][2],v[1][3],1}}
        )
        local anglea = math.atan2(ay,ax)
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
        result.segment[i] = mm.matrix_multiply(result.segment[i],transform)[1]
    end
    table.insert(segments,result)
end

rtc.register_tex_cmd(
    "appendplane", function()
    append_plane{
        a              =  token.get_macro("tikz@td@cs@p@a"),
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