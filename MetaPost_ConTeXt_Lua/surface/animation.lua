require("MetaPost_ConTeXt_Lua.linalg")
require("MetaPost_ConTeXt_Lua.BSPtree")


-- generate triangles
triangles = {}
for longitude = 0, 2*la.pi, la.pi/4 do
    for latitude = 0, 2*la.pi, la.pi/4 do
        -- get vertices
        A = la.sphere(longitude,latitude)
        B = la.sphere(longitude+la.pi/4,latitude)
        C = la.sphere(longitude,latitude+la.pi/4)
        D = la.sphere(longitude+la.pi/4,latitude+la.pi/4)
        table.insert(triangles,{A,B,D})
        table.insert(triangles,{A,C,D})
    end
end

for triangle_set_pos = 1, #triangles, 1 do
    v1 = la.sub(triangles[triangle_set_pos][2],triangles[triangle_set_pos][1])
    v2 = la.sub(triangles[triangle_set_pos][3],triangles[triangle_set_pos][1])
    normal = la.cross(v1,v2)
    d = la.inner(normal,triangles[triangle_set_pos][1])
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