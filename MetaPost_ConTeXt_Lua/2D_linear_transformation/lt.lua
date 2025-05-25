require("MetaPost_ConTeXt_Lua.linalg")

local segments = {}

transformation = {
    {1,-1/2,0}
    ,{1,1,0}
    ,{0,0,1}
}

xmin = -5
xmax = 5
xsamp = 10
xstep = (xmax-xmin)/(xsamp-1)

ymin = -5
ymax = 5
ysamp = 10
ystep = (ymax-ymin)/(ysamp-1)

for xpos = xmin, xmax, xstep do
    local segment = {
        {xpos,ymin,1}
        ,{xpos,ymax,1}
    }
    segment = la.mult(segment,transformation)
    table.insert(segments,segment)
end

for ypos = ymin, ymax, ystep do
    local segment = {
        {xmin,ypos,1}
        ,{xmax,ypos,1}
    }
    segment = la.mult(segment,transformation)
    table.insert(segments,segment)
end

function main()
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
    context.stopMPpage()
end

interfaces.implement {
        name = "mymacro",
        public = true,
        arguments = { },
        actions = main,
}