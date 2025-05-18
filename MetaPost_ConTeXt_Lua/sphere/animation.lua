require("MetaPost_ConTeXt_Lua.linalg")

local longitude_paths = {}

count0 = 0
for longitude = 0, 2*la.pi, la.pi/4 do
    count0 = count0 + 1
    longitude_paths[count0] = {}
    count = 0
    for latitude = 0, 2*la.pi, la.pi/18 do
        count = count + 1
        longitude_paths[count0][count] = la.sphere(longitude,latitude)
    end
end




function make_picture()
    local alpha = la.pi/6
    local beta = la.pi/6
    local gamma
    local transformed_paths
    for gamma = 0, 2*la.pi, la.pi/36 do
        context.startMPpage()
        for i = 1, #longitude_paths - 1, 1 do
            transformed_paths = la.mult(longitude_paths[i],la.ZYZrotation3D(alpha,beta,gamma))
            context("draw (-5 cm,-5 cm) -- (5 cm,-5 cm) -- (5 cm,5 cm) -- (-5 cm,5 cm);")
            for segment = 1, #transformed_paths - 1, 1 do
                context(
                    string.format(
                        [[
                            draw (%f cm,%f cm) -- (%f cm,%f cm);
                        ]]
                        ,transformed_paths[segment][1]
                        ,transformed_paths[segment][2]
                        ,transformed_paths[segment+1][1]
                        ,transformed_paths[segment+1][2]
                    )
                )
            end
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