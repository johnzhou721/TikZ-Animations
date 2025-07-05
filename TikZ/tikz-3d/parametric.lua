-- parametric.lua
local mm = require "matrix_math"
local rtc = require "register_tex_cmd"
local ss = require "segment_sorting"
_ENV = _G -- use this to *add* the functions in test
for i,j in pairs(mm) do
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
