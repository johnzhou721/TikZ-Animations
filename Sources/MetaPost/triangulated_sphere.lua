local po = require("parametric_objects")
local la = require("linear_algebra")

function main()
    po.append_surface({
        u_start      = 0,
        u_end        = la.tau,
        u_samples    = 36,
        v_start      = 0,
        v_end        = la.tau/2,
        v_samples    = 18,
        fx           = "math.sin(v)*math.cos(u)",
        fy           = "math.sin(v)*math.sin(u)",
        fz           = "math.cos(v)",
        fill_options = "withcolor darkred withtransparency (0.5,0.7);",
        draw_options = "withtransparency (0.5,0.5);"
    })

    local T = la.ZYZrotation3D(la.tau/6,la.tau/6,la.tau/6)
    for i, seg in ipairs(po.segments) do
        local newseg = la.mult(seg[1],T)
        po.segments[i][1] = newseg
    end

    po.render_segments()
end

interfaces.implement {
    name      = "uniquename",
    actions   = main,
    public = true,
    arguments = { },
}

