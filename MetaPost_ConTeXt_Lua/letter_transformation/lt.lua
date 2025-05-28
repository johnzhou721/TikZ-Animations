la = require("MetaPost_ConTeXt_Lua.linalg")

segments = {}
function get_lines()
    segments = {}
    xmin = -5
    xmax = 5
    xsamp = 11
    xstep = (xmax-xmin)/(xsamp-1)

    ymin = -5
    ymax = 5
    ysamp = 11
    ystep = (ymax-ymin)/(ysamp-1)

    for xpos = xmin, xmax, xstep do
        local segment = {
            {xpos,ymin,1}
            ,{xpos,ymax,1}
        }
        table.insert(segments,segment)
        segment = la.mult(segment,transformation)
        table.insert(segments,segment)
    end

    for ypos = ymin, ymax, ystep do
        local segment = {
            {xmin,ypos,1}
            ,{xmax,ypos,1}
        }
        table.insert(segments,segment)
        segment = la.mult(segment,transformation)
        table.insert(segments,segment)
    end
end

function main()
    max = 35
    for frame = 0, max, 1 do
        transformation = {
            {1,-1/2*frame/max,0}
            ,{1*frame/max,1,0}
            ,{0,0,1}
        }
        get_lines()
        context.startMPpage()
            for pos = 1, #segments, 1 do
                context(
                    string.format(
                        [[
                            draw (%f cm,%f cm) -- (%f cm,%f cm);
                        ]]
                        ,segments[pos][1][1]
                        ,segments[pos][1][2]
                        ,segments[pos][2][1]
                        ,segments[pos][2][2]
                    )
                )
            end
            context(
                string.format(
                    [[
                        picture p[] ;
                        transform T ;
                        xpart T = %f ;
                        ypart T = %f ;
                        xxpart T = %f ;
                        xypart T = %f ;
                        yxpart T = %f ;
                        yypart T = %f ;
                        p[1] := textext("M") scaled 20 transformed T ;
                        draw p[1] withcolor darkyellow ;

                    ]]
                    ,0,0
                    ,1,1*frame/max
                    ,-1/2*frame/max,1
                )
            )
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