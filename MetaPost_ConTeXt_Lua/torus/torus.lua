require("MetaPost_ConTeXt_Lua.linalg")

local triangles = {}
for longitude = 0, 2*la.pi, la.pi/18 do
    for latitude = 0, 2*la.pi, la.pi/18 do
        local A = la.mult(la.sphere(longitude,latitude),la.translate3D(2*math.cos(longitude),2*math.sin(longitude),0))
        local B = la.mult(la.sphere(longitude+la.pi/18,latitude),la.translate3D(2*math.cos(longitude+la.pi/18),2*math.sin(longitude+la.pi/18),0))
        local C = la.mult(la.sphere(longitude,latitude+la.pi/18),la.translate3D(2*math.cos(longitude),2*math.sin(longitude),0))
        local D = la.mult(la.sphere(longitude+la.pi/18,latitude+la.pi/18),la.translate3D(2*math.cos(longitude+la.pi/18),2*math.sin(longitude+la.pi/18),0))
        table.insert(triangles, { A, B, D })
        table.insert(triangles, { A, C, D })
    end
end

function main()
    camera = {{0,0,1,1}}
    for tri = 1, #triangles, 1 do
        span1 = la.sub(triangles[tri][2],triangles[tri][1])
        span2 = la.sub(triangles[tri][3],triangles[tri][1])
        normal = la.cross(span1,span2)
        if la.inner(normal,camera) < 0 then
            normal = la.mult(normal,la.scale3D(-1))
        end
        D = la.inner(normal,triangles[tri][1])
        upper = {}
        lower = {}
        for tri2 = 1, #triangles, 1 do
            if tri2 ~= tri1 then
                A,B,C = triangles[tri2][1],triangles[tri2][2],triangles[tri2][3]
                A_test = la.inner(A,normal) + D
                B_test = la.inner(B,normal) + D
                C_test = la.inner(C,normal) + D
                if (
                    A_test > 0 and
                    B_test > 0 and
                    C_test > 0
                ) then
                    table.insert(upper,triangles[tri2])
                elseif (
                    A_test < 0 and
                    B_test < 0 and
                    C_test < 0
                ) then
                    table.insert(lower,triangles[tri2])
                else
                    -- split them up and add the pieces to the correct table
                end
            end
        end
        triangles = {}
        for i = 1, #upper, 1 do
            table.insert(triangles,upper[i])
        end
        for i = 1, #lower, 1 do
            table.insert(triangles,lower[i])
        end
    end
    context.startMPpage()
    for tri = 1, #triangles, 1 do
        context(
            string.format(
                [[
                    draw (%f cm,%f cm) -- (%f cm,%f cm) -- (%f cm,%f cm) -- cycle;
                ]]
                ,triangles[tri][1][1][1]
                ,triangles[tri][1][1][2]
                ,triangles[tri][2][1][1]
                ,triangles[tri][2][1][2]
                ,triangles[tri][3][1][1]
                ,triangles[tri][3][1][2]
            )
        )
    end
    context.endMPpage()
end

interfaces.implement {
        name = "mymacro",
        public = true,
        arguments = { },
        actions = main,
}