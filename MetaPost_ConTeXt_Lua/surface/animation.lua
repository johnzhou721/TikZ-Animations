require("MetaPost_ConTeXt_Lua.linalg")
require("MetaPost_ConTeXt_Lua.BSPtree")


function split_triangle_by_plane(tri,normal,d)
    
end


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

for triangle_pos = 1, #triangles, 1 do
    A,B,C = table.unpack(triangles[triangle_pos])
    A = table.remove(A,4)
    B = table.remove(B,4)
    C = table.remove(C,4)
    AB = la.sub(B,A)
    AC = la.sub(C,A)
    normal = la.cross(AB,AC)
    d = la.inner(normal,A)
    for second_triangle_pos = 1, #triangles, 1 do
        if second_triangle_pos ~= triangle_pos then
            D,E,F = table.unpack(triangles[second_triangle_pos])
            D = table.remove(D,4)
            E = table.remove(E,4)
            F = table.remove(F,4)
            D_test = la.inner(la.sub(D,A),normal)
            E_test = la.inner(la.sub(E,A),normal)
            F_test = la.inner(la.sub(F,A),normal)
            if ((not (D_test>0 and E_test>0 and F_test>0)) and (not (D_test<0 and E_test<0 and F_test<0))) then

            end
        end
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