require("MetaPost_ConTeXt_Lua.linalg")

S_segments = {}
B_segments = {}
TS_segments = {}
TB_segments = {}
function get_lines()
    S_segments = {}
    B_segments = {}
    TS_segments = {}
    TB_segments = {}
    xmin = -5
    xmax = 5
    xsamp = 11
    xstep = (xmax-xmin)/(xsamp-1)

    ymin = -5
    ymax = 5
    ysamp = 11
    ystep = (ymax-ymin)/(ysamp-1)

    for xpos = xmin, xmax, xstep do
        local S_seg = {
            {xpos,ymin,1}
            ,{xpos,ymax,1}
        }
        table.insert(S_segments, S_seg)
        TS_seg = la.mult(S_seg,S_transformation)
        table.insert(TS_segments, TS_seg)

        B_seg = la.mult(S_seg,B_basis)
        table.insert(B_segments, B_seg)
        TB_seg = la.mult(B_seg, B_transformation)
        TB_seg = la.mult(TB_seg, la.inverse(B_basis))
        table.insert(TB_segments, TB_seg)

    end

    for ypos = ymin, ymax, ystep do
        local S_seg = {
            {xmin,ypos,1}
            ,{xmax,ypos,1}
        }
        table.insert(S_segments, S_seg)
        TS_seg = la.mult(S_seg,S_transformation)
        table.insert(TS_segments, TS_seg)

        B_seg = la.mult(S_seg,B_basis)
        table.insert(B_segments, B_seg)
        TB_seg = la.mult(B_seg, B_transformation)
        TB_seg = la.mult(TB_seg, la.inverse(B_basis))
        table.insert(TB_segments, TB_seg)
    end
end

function main()
    max = 35
    for frame = 0, max, 1 do
        standard_basis = identity_matrix(3)
        B_basis = la.mult(standard_basis,la.rotate2D(30))
        S_transformation = {
            {1,-1/2*frame/max,0}
            ,{1*frame/max,1,0}
            ,{0,0,1}
        }
        B_transformation = la.mult(la.inverse(B_basis), la.mult(S_transformation, B_basis))
        get_lines()
        context.startMPpage()
            for pos = 1, #S_segments, 1 do
                context(
                    string.format(
                        [[
                            draw (%f cm,%f cm) -- (%f cm,%f cm) withcolor black;
                        ]]
                        ,S_segments[pos][1][1]
                        ,S_segments[pos][1][2]
                        ,S_segments[pos][2][1]
                        ,S_segments[pos][2][2]
                    )
                )
            end
            for pos = 1, #TS_segments, 1 do
                context(
                    string.format(
                        [[
                            draw (%f cm,%f cm) -- (%f cm,%f cm) withcolor darkyellow;
                        ]]
                        ,TS_segments[pos][1][1]
                        ,TS_segments[pos][1][2]
                        ,TS_segments[pos][2][1]
                        ,TS_segments[pos][2][2]
                    )
                )
            end

            for pos = 1, #B_segments, 1 do
                context(
                    string.format(
                        [[
                            draw (%f cm,%f cm) -- (%f cm,%f cm) withcolor black;
                        ]]
                        ,B_segments[pos][1][1]
                        ,B_segments[pos][1][2]
                        ,B_segments[pos][2][1]
                        ,B_segments[pos][2][2]
                    )
                )
            end
            for pos = 1, #TB_segments, 1 do
                context(
                    string.format(
                        [[
                            draw (%f cm,%f cm) -- (%f cm,%f cm) withcolor darkred;
                        ]]
                        ,TB_segments[pos][1][1]
                        ,TB_segments[pos][1][2]
                        ,TB_segments[pos][2][1]
                        ,TB_segments[pos][2][2]
                    )
                )
            end
            context(
                [[
                    clip currentpicture to (-5cm,-5cm) -- (5cm,-5cm) -- (5cm,5cm) -- (-5cm,5cm) -- cycle;
                ]]
            )
        context.stopMPpage()
    end
end

interfaces.implement {
        name = "mymacro",
        public = true,
        arguments = { },
        actions = main,
}