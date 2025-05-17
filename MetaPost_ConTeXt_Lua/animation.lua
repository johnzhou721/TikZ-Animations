list_of_line_segments = {}
for t = 0, 2*3.14159, 2*3.14159/100 do
    table.insert(
        list_of_line_segments
        ,{
            math.cos(t)
            ,math.sin(t)
        }
    )
end

function make_picture()
context.startMPcode()
    for seg = 1, #list_of_line_segments - 1, 1 do
        context(string.format(
            [[
                draw (%f cm,%f cm) -- (%f cm,%f cm);
            ]]
            ,list_of_line_segments[seg][1]
            ,list_of_line_segments[seg][2]
            ,list_of_line_segments[seg+1][1]
            ,list_of_line_segments[seg+1][2]
        ))
    end
context.stopMPcode()
end