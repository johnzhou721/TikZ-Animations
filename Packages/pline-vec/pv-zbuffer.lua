segments = {}

function append_surface(u_start, u_end, u_samples,
                        v_start, v_end, v_samples,
                        fx, fy, fz)

    local u_step = (u_end - u_start) / (u_samples  - 1)
    local v_step = (v_end - v_start) / (v_samples  - 1)

    local gx = load("return function(u,v) return " .. fx .. " end")()
    local gy = load("return function(u,v) return " .. fy .. " end")()
    local gz = load("return function(u,v) return " .. fz .. " end")()

    local function surface(u, v)
        return { gx(u,v), gy(u,v), gz(u,v) }
    end

    for i = 0, u_samples-2 do
        local u = u_start + i * u_step
        local color_frac = (u - u_start) / (u_end - u_start)

        for j = 0, v_samples-2 do
            local v = v_start + j * v_step

            local A = surface(u,           v)
            local B = surface(u + u_step,  v)
            local C = surface(u,           v + v_step)
            local D = surface(u + u_step,  v + v_step)

            -- triangle A–B–D
            local mid1 = pv_average(A, B, D)
            local dp1  = pv_dot_product(observer, mid1)
            table.insert(segments, { dp1, A, B, D, color_frac })

            -- triangle A–C–D
            local mid2 = pv_average(A, C, D)
            local dp2  = pv_dot_product(observer, mid2)
            table.insert(segments, { dp2, A, C, D, color_frac })
        end
    end
end


function render_segments()
    table.sort(segments, function(a, b) return a[1] < b[1] end)

    for _, seg in ipairs(segments) do
        local _, P, Q, R, col = table.unpack(seg)
        local pct = math.floor(100 * col)
        tex.print(string.format("\\SetColor{%d}", pct))
        tex.print("\\draw[line join=round, preaction={fill=MyColor}]")
        tex.print(
          string.format("(%f,%f,%f) -- (%f,%f,%f) -- (%f,%f,%f) -- cycle;",
            P[1],P[2],P[3],
            Q[1],Q[2],Q[3],
            R[1],R[2],R[3]
          )
        )
    end

    segments = {}
end
