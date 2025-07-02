-- parametric.lua
local rtc = require "register_tex_cmd"


local segments = {}
local observer_dir = { { 0, 0, -1, 1} }
local observer_pos = { { 0, 0, 0, 1} }

local function append_curve(hash)
    local u_start      = tonumber(hash.u_start)
    local u_stop       = tonumber(hash.u_stop)
    local u_samples    = tonumber(hash.u_samples)
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

    local x = single_string_function(x)
    local y = single_string_function(y)
    local z = single_string_function(z)

    local u_step = (u_stop - u_start) / (u_samples - 1)

    local function parametric_curve(u)
        return {x(u),y(u),z(u),1}
    end

    for i = 0, u_samples - 2 do
        local u = u_start + i * u_step
        local A = parametric_curve(u)
        local B = parametric_curve(u+u_step)
        table.insert( segments, { {A,B}, draw_options, name } )
    end
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
