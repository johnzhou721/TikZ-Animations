

register_tex_cmd("appendcurve", function(name)
    local u_min        = rtc.math_expr(example_keys["u min"])
    local u_max        = rtc.math_expr(example_keys["u max"])
    local u_samples    = rtc.math_expr(example_keys["u samples"])
    local fx           = math_func(example_keys["fx"])
    local fy           = math_func(example_keys["fy"])
    local fz           = math_func(example_keys["fz"])

    local function parametric_curve(u)
        return { fx(u), fy(u), fz(u), 1 }
    end

    for i = 0, u_samples - 2 do
        local u = u_min + i * u_step
        local A = parametric_curve(u)
        local B = parametric_curve(u + u_step)

        insert(segments, { { A, B }, name })
    end
end, { "string" })

local document_catcodes = token.create("c_document_cctab").index
local draw_formatter = string.formatters["\\draw[/example/@draw options@%s]"]
local point_formatter = string.formatters["(%f, %f) -- (%f, %f)"]

register_tex_cmd("rendersegments", function()
    local tex_code = {}
    local last_name = nil
    for _, segment in ipairs(segments) do
        local S, E = segment[1][1], segment[1][2]
        local name = segment[2]
        if name ~= last_name then
            if #tex_code > 0 then
                insert(tex_code, ";")
            end
            insert(tex_code, draw_formatter(name))
            last_name = name
        end
        insert(tex_code, point_formatter(
            S[1], S[2],
            E[1], E[2]
        ))
    end
    insert(tex_code, ";")
    tex.sprint(document_catcodes, tex_code)
    segments = {}
end, {})