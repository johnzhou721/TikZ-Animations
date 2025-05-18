require("MetaPost_ConTeXt_Lua.linalg")



local segs = {
    {0,0,1}
    ,{0,1,1}
}

function make_picture()
    for angle = 0, 2*la.pi, la.pi/18 do
        local transformed_segs = la.mult(
            segs
            ,la.mult(
                la.rotate2D(angle)
                ,la.translate2D(3,4)
            )
        )
        context.startMPpage()
        context("draw (-5 cm,-5 cm) -- (5 cm,-5 cm) -- (5 cm,5 cm) -- (-5 cm,5 cm);")
        context(
            string.format(
                [[
                    draw (%f cm,%f cm) -- (%f cm,%f cm);
                ]]
                ,transformed_segs[1][1]
                ,transformed_segs[1][2]
                ,transformed_segs[2][1]
                ,transformed_segs[2][2]
            )
        )
        context.stopMPpage()
    end
end

interfaces.implement {
        name = "mymacro",
        public = true,
        arguments = { },
        actions = make_picture,
}