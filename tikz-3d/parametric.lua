-- parametric.lua
local rtc = require "register_tex_cmd"


local segments = {}
local observer_dir = { { 0, 0, -1, 1} }
local observer_pos = { { 0, 0, 0, 1} }

local function append_curve(hash)
    local u_start      = hash.u_start
    local u_stop       = hash.u_stop
    local u_samples    = hash.u_samples
    local x            = hash.x
    local y            = hash.y
    local z            = hash.z
    local draw_options = hash.draw_options
    local name         = hash.name

    local function single_string_function(str)
        if not str or str == "" then
            return nil
        end
        return load(("return function(u) return %s end"):format(str))()
    end

    local function single_string_expression(str)
        if not str or str == "" then
            return nil
        end
        return load(("return %s"):format(str))()
    end

    x = single_string_function(x)
    y = single_string_function(y)
    z = single_string_function(z)

    u_start = single_string_expression(u_start)
    u_stop = single_string_expression(u_stop)

    local u_step = (u_stop - u_start) / (u_samples - 1)

    local function parametric_curve(u)
        return { { x =  x(u), y = y(u), z = z(u), w = 1 } }
    end

    for i = 0, u_samples - 2 do
        local u = u_start + i * u_step
        local A = parametric_curve(u)
        local B = parametric_curve(u+u_step)
        table.insert(segments, { segment = { A, B }, draw_options = draw_options, name = name })
    end
end

local function render_segments()
    for _, segment in ipairs(segments) do
        if #segment.segment == 2 then
            local S, E = segment.segment[1], segment.segment[2]
            local Sx, Sy = S[1].x, S[1].y
            local Ex, Ey = E[1].x, E[1].y
            local options = segment.draw_options
            tex.sprint(
                string.format(
                    "\\draw[%s] (%f,%f) -- (%f,%f);"
                    ,options,Sx, Sy, Ex, Ey
                )
            )
        end
    end
    segments = {}
end


rtc.register_tex_cmd(
    "appendcurve", function()
    append_curve{
        u_start      = token.get_macro("tikz@td@p@c@umin"),
        u_stop       = token.get_macro("tikz@td@p@c@umax"),
        u_samples    = token.get_macro("tikz@td@p@c@usamples"),
        x            = token.get_macro("tikz@td@p@c@x"),
        y            = token.get_macro("tikz@td@p@c@y"),
        z            = token.get_macro("tikz@td@p@c@z"),
        draw_options = token.get_macro("tikz@td@p@c@drawoptions"),
        name         = token.get_macro("tikz@td@p@c@name")
    } end,
    { }
)

rtc.register_tex_cmd("rendersegments", function() render_segments() end, { })
