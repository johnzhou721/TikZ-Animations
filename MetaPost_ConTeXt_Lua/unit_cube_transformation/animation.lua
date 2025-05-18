require("MetaPost_ConTeXt_Lua.linalg")

longitude_paths = {
    {0,0,0,1}
    ,{1,0,0,1}
    ,{1,1,0,1}
    ,{0,1,0,1}
    ,{0,0,0,1}
    ,{0,0,1,1}
    ,{1,0,1,1}
    ,{1,1,1,1}
    ,{0,1,1,1}
    ,{0,0,1,1}
}

transformation = {
    {1,0,0,1}
    ,{0,1,0,1}
    ,{0,0,1,1}
    ,{0,0,0,1}
}

--transformation = la.mult(la.ZYZrotation3D(0,la.pi/2,0),transformation)



function make_picture()
    context.startMPpage()
    transformed_paths = la.mult(longitude_paths,transformation)
    context("draw (-5 cm,-5 cm) -- (5 cm,-5 cm) -- (5 cm,5 cm) -- (-5 cm,5 cm);")
    for segment = 1, #transformed_paths - 1, 1 do
        a =  la.point_unique(
            transformed_paths[segment]
        )
        b =  la.point_unique(
            transformed_paths[segment+1]
        )
        context(
            string.format(
                [[
                    draw (%f cm,%f cm) -- (%f cm,%f cm);
                ]]
                ,a[1]
                ,a[2]
                ,b[1]
                ,b[2]
            )
        )
    end
    context.stopMPpage()
end

interfaces.implement {
        name = "mymacro",
        public = true,
        arguments = { },
        actions = make_picture,
}