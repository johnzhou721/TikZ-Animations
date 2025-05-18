require("MetaPost_ConTeXt_Lua.linalg")

local segments = {}

for longitude = 0, 2*la.pi, la.pi/18 do
    for latitude = 0, 2*la.pi, la.pi/18 do
        table.insert(segments,la.sphere(longitude,latitude))
    end
end

function make_picture()
    local alpha = 30
    local beta = 30
    local gamma
    local transformed_segs
    for gamma = 0, 2*la.pi, la.pi/18 do
        transformed_segs = la.mult(segments,la.ZYZrotation3D(alpha,beta,gamma))
        context.startMPpage()
        context("draw (-5 cm,-5 cm) -- (5 cm,-5 cm) -- (5 cm,5 cm) -- (-5 cm,5 cm);")
        for segment = 1, #transformed_segs - 1, 1 do
            context(
                string.format(
                    [[
                        draw (%f cm,%f cm) -- (%f cm,%f cm);
                    ]]
                    ,transformed_segs[segment][1]
                    ,transformed_segs[segment][2]
                    ,transformed_segs[segment+1][1]
                    ,transformed_segs[segment+1][2]
                )
            )
        end
        context.stopMPpage()
    end
end

interfaces.implement {
        name = "mymacro",
        public = true,
        arguments = { },
        actions = make_picture,
}