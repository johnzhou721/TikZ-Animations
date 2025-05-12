segments = {}

function append_surface(
    u_start,u_end,u_samples
    ,v_start,v_end,v_samples
    ,fx,fy,fz
)
    x_col_step = 100/(u_end-u_start)
    u_step = (u_end-u_start)/u_samples
    v_step = (v_end-v_start)/v_samples

    function surface(u,v)
        local x = fx(u, v)
        local y = fy(u, v)
        local z = fz(u, v)
        result = {x,y,z}
        return result
    end

    count_1 = 0
    for u = u_start, u_end, u_step do
        count_1 = count_1 + 1
        count_2 = 0
        for v = v_start, v_end, v_step do
            count_2 = count_2 + 1
            x_col = math.floor(u*x_col_step) -- this is the wrong calculation, fix later
            if (count_1 ~= u_samples+1 and count_2 ~= v_samples) then
                a = surface(u,v)
                b = surface(u+u_step,v)
                c = surface(u,v+v_step)
                d = surface(u+u_step,v+v_step)
            end
            avg_1 = pv_average(a,b,d)
            avg_2 = pv_average(a,c,d)
            dp_1 = pv_dot_product(observer,avg_1)
            dp_2 = pv_dot_product(observer,avg_2)
            ab = pv_difference(a,b)
            ac = pv_difference(a,c)
            ad = pv_difference(a,d)
            nab = pv_cross_product(ab,ad)
            nab = pv_normalize_vector(nab)
            nac = pv_cross_product(ac,ad)
            nac = pv_normalize_vector(nac)
            table.insert(segments,{dp_1,a,b,d,x_col})
            table.insert(segments,{dp_2,a,c,d,x_col})
        end
    end

end

function append_curve(
    u_start,u_end,u_step
    ,fx,fy,fz
)
    x_col_step = 100/(u_end-u_start)
    u_step = (u_end-u_start)/u_samples

    function curve(u)
        x,y,z = fx,fy,fz
        result = {x,y,z}
        return result
    end

    for u = u_start, u_end, u_samples do

    end
end

function render_segments()
    table.sort(
        segments
        ,function(a, b)
            return a[1] < b[1]
        end
    )
    for index, value in ipairs(segments) do
        --tex.print(string.format("\\SetColor{%f}",x_col))
        tex.print(
            "\\draw[line join = round,preaction = {fill = MyColor}]"
        )
        tex.print(string.format("(%f,%f,%f) --",value[2][1],value[3][1],value[4][1]))
        tex.print(string.format("(%f,%f,%f) --",value[2][2],value[3][2],value[4][2]))
        tex.print(string.format("(%f,%f,%f) -- cycle;",value[2][3],value[3][3],value[4][3]))
    end
    segments = {}
end