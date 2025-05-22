require("MetaPost_ConTeXt_Lua.linalg")

triangles = {}
for longitude = 0, 2*la.pi, la.pi/9 do
    for latitude = -la.pi/2, la.pi/2, la.pi/9 do
        -- get vertices
        A = la.sphere(longitude,latitude)
        B = la.sphere(longitude+la.pi/9,latitude)
        C = la.sphere(longitude,latitude+la.pi/9)
        D = la.sphere(longitude+la.pi/9,latitude+la.pi/9)
        table.insert(triangles,{A,B,D})
        table.insert(triangles,{A,C,D})
    end
end




function make_picture()
    local alpha = la.pi/6
    local beta = la.pi/6
    local gamma
    local transformed_paths
    for gamma = 0, 2*la.pi, la.pi/36 do
        context.startMPpage()
        context("draw (-5 cm,-5 cm) -- (5 cm,-5 cm) -- (5 cm,5 cm) -- (-5 cm,5 cm);")
        for i = 1, #triangles, 1 do
            transformed_paths = la.mult(triangles[i],la.ZYZrotation3D(alpha,beta,gamma))
            for segment = 1, #transformed_paths, 1 do
                context(
                    string.format(
                        [[
                            draw (2*%f cm,2*%f cm) -- (2*%f cm,2*%f cm) -- (2*%f cm,2*%f cm) -- cycle;
                        ]]
                        ,transformed_paths[1][1]
                        ,transformed_paths[1][2]
                        ,transformed_paths[2][1]
                        ,transformed_paths[2][2]
                        ,transformed_paths[3][1]
                        ,transformed_paths[3][2]
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