-- elliptic_mobius_transformation.lua

-- https://tex.stackexchange.com/a/747040
--- Creates a TeX command that evaluates a Lua function
---
--- @param name string The name of the `\csname` to define
--- @param func function
--- @param args table<string> The TeX types of the function arguments
--- @param protected boolean|nil Define the command as `\protected`
--- @return nil
local function register_tex_cmd(name, func, args, protected)
    -- The extended version of this function uses `N` and `w` where appropriate,
    -- but only using `n` is good enough for exposition purposes.
    name = "__jasper_" .. name .. ":" .. ("n"):rep(#args)

    -- Push the appropriate scanner functions onto the scanning stack.
    local scanners = {}
    for _, arg in ipairs(args) do
        scanners[#scanners+1] = token['scan_' .. arg]
    end

    -- An intermediate function that properly "scans" for its arguments
    -- in the TeX side.
    local scanning_func = function()
        local values = {}
        for _, scanner in ipairs(scanners) do
            values[#values+1] = scanner()
        end

        func(table.unpack(values))
    end

    local index = luatexbase.new_luafunction(name)
    lua.get_functions_table()[index] = scanning_func

    if protected then
        token.set_lua(name, index, "protected")
    else
        token.set_lua(name, index)
    end
end

--[[
    Matrix multiplication
]]
function matrix_multiply(A,B)
    local rows_A = #A
    local columns_A = #A[1]
    local rows_B = #B
    local columns_B = #B[1]
    assert(
        columns_A == rows_B
        ,string.format(
            [[
                Wrong size matrices for multiplication.
                Size A: %f,%f Size B: %f,%f
            ]]
            ,rows_A,columns_A
            ,rows_B,columns_B
        )
    )
    local product = {}
    for row = 1, rows_A, 1 do
        product[row] = {}
        for column = 1, columns_B, 1 do
            product[row][column] = 0
            for dot_product_step = 1, columns_A, 1 do
                product[row][column] = (
                    product[row][column] + 
                    A[row][dot_product_step] * 
                    B[dot_product_step][column]
                )
            end
        end
    end
    return product
end

function yrotation3D(angle)
    local c = math.cos(angle)
    local s = math.sin(angle)
    return {
        {c,0,s,0}
        ,{0,1,0,0}
        ,{-s,0,c,0}
        ,{0,0,0,1}
    }
end

function zrotation3D(angle)
    local c = math.cos(angle)
    local s = math.sin(angle)
    return {
        {c,s,0,0}
        ,{-s,c,0,0}
        ,{0,0,1,0}
        ,{0,0,0,1}
    }
end

--[[
    ZYZ Euler angle rotation matrix
]]
function euler(alpha,beta,gamma)
    return matrix_multiply(
        zrotation3D(gamma)
        ,matrix_multiply(
            yrotation3D(beta)
            ,zrotation3D(alpha)
        )
    )
end

function eulerx(point,alpha,beta,gamma)
    local T = euler(alpha,beta,gamma)
    local P = matrix_multiply(point,T)
    return P[1][1]
end

function eulery(point,alpha,beta,gamma)
    local T = euler(alpha,beta,gamma)
    local P = matrix_multiply(point,T)
    return P[1][2]
end

function eulerz(point,alpha,beta,gamma)
    local T = euler(alpha,beta,gamma)
    local P = matrix_multiply(point,T)
    return P[1][3]
end

function stereographic_projection(tbl)
    local x = tbl[1][1]
    local y = tbl[1][2]
    local z = tbl[1][3]
    return {{x / (1 - z), y / (1 - z), 0, 1}}
end

function sphere(theta, phi)
    local s = math.sin(theta)
    return {{
        s * math.cos(phi),
        s * math.sin(phi),
        math.cos(theta),
        1
    }}
end

local function single_string_expression(str)
    return load(("return %s"):format(str))()
end

local segments = {}
local observer_dir = { { 0, 0, -1, 1} }
local observer_pos = { { 0, 0, 0, 1} }

local function append_curve(hash)
    local u_start      = hash.u_start
    local u_stop       = hash.u_stop
    local u_samples    = hash.u_samples
    local x            = hash.x
    local y            = hash.y
    local z            = hash.z
    local draw_options = hash.draw_options
    local name         = hash.name

    local function single_string_function(str)
        return load(("return function(u) return %s end"):format(str))()
    end

    x = single_string_function(x)
    y = single_string_function(y)
    z = single_string_function(z)

    u_start = single_string_expression(u_start)
    u_stop = single_string_expression(u_stop)

    local u_step = (u_stop - u_start) / (u_samples - 1)

    local function parametric_curve(u)
        return { x(u), y(u), z(u), 1 }
    end

    for i = 0, u_samples - 2 do
        local u = u_start + i * u_step
        local A = parametric_curve(u)
        local B = parametric_curve(u+u_step)
        table.insert(segments, { segment = { A, B }, draw_options = draw_options, name = name })
    end
end

local function render_segments()
    for _, segment in ipairs(segments) do
        if #segment.segment == 2 then
            local S, E = segment.segment[1], segment.segment[2]
            local Sx, Sy = S[1], S[2]
            local Ex, Ey = E[1], E[2]
            local options = segment.draw_options
            local abs = math.abs 
            if (abs(Sx)<100 and abs(Sy)<100 and abs(Ex)<100 and abs(Ey)<100) then
                tex.sprint(
                    string.format(
                        "\\draw[%s] (%f,%f) -- (%f,%f);"
                        ,options,Sx, Sy, Ex, Ey
                    )
                )
            end
        end
    end
    segments = {}
end

register_tex_cmd(
    "appendcurve", function()
    append_curve{
        u_start      = token.get_macro("tikz@td@p@c@umin"),
        u_stop       = token.get_macro("tikz@td@p@c@umax"),
        u_samples    = token.get_macro("tikz@td@p@c@usamples"),
        x            = token.get_macro("tikz@td@p@c@x"),
        y            = token.get_macro("tikz@td@p@c@y"),
        z            = token.get_macro("tikz@td@p@c@z"),
        draw_options = token.get_macro("tikz@td@p@c@drawoptions"),
        name         = token.get_macro("tikz@td@p@c@name")
    } end,
    { }
)

register_tex_cmd("rendersegments", function() render_segments() end, { })
