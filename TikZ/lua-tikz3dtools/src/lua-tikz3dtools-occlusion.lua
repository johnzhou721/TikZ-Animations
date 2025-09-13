
-- lua-tikz3dtools-occlusion.lua

--[[
    We use homogeneous vector convention throughout
    {{x, y, z, w, 1}}
]]
--- The dot product.
--- @param u table<table<number>> a vector
--- @param v table<table<number>> another vector
--- @return number the dot product
local function dot_product(u, v)
    local a, b = u[1], v[1]
    return a[1]*b[1] + a[2]*b[2] + a[3]*b[3]
end

--- Scalar multiplication
local function scalar_multiplication(a, v)
    local tmp = v[1]
    return { {a*tmp[1], a*tmp[2], a*tmp[3], 1} }
end

local function vector_subtraction(u, v)
    local U = u[1]
    local V = v[1]
    return { {U[1]-V[1], U[2]-V[2], U[3]-V[3], 1} }
end

local function vector_addition(u, v)
    local U = u[1]
    local V = v[1]
    return { {U[1]+V[1], U[2]+V[2], U[3]+V[3], 1} }
end

local function distance(P1, P2)
    local A = P1[1]
    local B = P2[1]
    return math.sqrt(
        (A[1]-B[1])^2 +
        (A[2]-B[2])^2 +
        (A[3]-B[3])^2
    )
end

--- The orthogonal vector projection.
--- @param u table<table<number>> the vector being projected onto
--- @param v table<table<number>> the vector being projected
--- @return table<table<number>> the resulting projection
local function orthogonal_vector_projection(u, v)
    return scalar_multiplication(
        dot_product(v, u) / dot_product(u, u),
        u
    )
end

local function length(v)
    local V = v[1]
    return math.sqrt((V[1])^2 + (V[2])^2 + (V[3])^2)
end

local function cross_product(u,v)
    local x = u[1][2]*v[1][3]-u[1][3]*v[1][2]
    local y = u[1][3]*v[1][1]-u[1][1]*v[1][3]
    local z = u[1][1]*v[1][2]-u[1][2]*v[1][1]
    local result = { {x, y, z, 1} }
    return result
end

local function sign(number)
    if number > -0.0000001 then return "positive" end
    return "negative"
end


--- Occlusion sorts two points.
--- @param P1 table<table<number>> a point
--- @param P2 table<table<number>> another point
--- @return boolean or nil whether P1 is in front
local function point_point_occlusion_sort(P1, P2)
    --[[
        If the points are not the same point, then calculate their
        depth directly.
    ]]
    if distance(P1, P2) > 0.0000001 then 
        if distance({{P1[1][1], P1[1][2], 0, 1}}, {{P2[1][1], P2[1][2], 0, 1}}) < 0.0000001 then
            return P1[1][3] > P2[1][3]
        end
    end
    return nil
end

-- Gauss-Jordan solver (column-major)
-- AugCols: array of n+1 columns, each column is an array of n numbers.
-- Options (optional):
--   opts.copy (default true)  -> if true, solver works on a copy and does not mutate AugCols
--   opts.eps  (default 1e-12) -> pivot tolerance
-- Returns: x (array 1..n) on success, or nil, reason on failure.
local function gauss_jordan_cols(AugCols, opts)
    opts = opts or {}
    local copy_input = (opts.copy == nil) and true or not not opts.copy
    local eps = opts.eps or 1e-12

    -- basic validation
    local m = #AugCols
    if m == 0 then return {}, nil end
    local n = #AugCols[1]
    if m ~= n + 1 then return nil, "bad_matrix_size (need n+1 columns for n rows)" end
    for c = 1, m do
        if #AugCols[c] ~= n then return nil, "bad_column_length" end
    end

    -- clone columns if requested
    local cols = AugCols
    if copy_input then
        cols = {}
        for c = 1, m do
            local col = {}
            for r = 1, n do col[r] = AugCols[c][r] end
            cols[c] = col
        end
    end

    -- Gauss-Jordan elimination
    for i = 1, n do
        -- find pivot row (max abs value in column i for rows i..n)
        local pivot_row = i
        local maxval = math.abs(cols[i][i])
        for r = i+1, n do
            local v = math.abs(cols[i][r])
            if v > maxval then
                maxval = v
                pivot_row = r
            end
        end

        if maxval < eps then
            return nil, "singular"
        end

        -- swap rows i and pivot_row across all columns if needed
        if pivot_row ~= i then
            for c = 1, m do
                cols[c][i], cols[c][pivot_row] = cols[c][pivot_row], cols[c][i]
            end
        end

        -- normalize pivot row so pivot becomes 1
        local pivot = cols[i][i]
        for c = 1, m do
            cols[c][i] = cols[c][i] / pivot
        end

        -- eliminate all other rows at column i
        for r = 1, n do
            if r ~= i then
                local factor = cols[i][r]
                if factor ~= 0 then
                    for c = 1, m do
                        cols[c][r] = cols[c][r] - factor * cols[c][i]
                    end
                    -- numerical cleanup
                    cols[i][r] = 0
                end
            end
        end
    end

    -- solution is in the last column (RHS), rows 1..n
    local x = {}
    for i = 1, n do
        x[i] = cols[m][i]
    end
    return x
end

--[[ Example usage:
local aug = {
  {2, 1},     -- col 1 (a11, a21)
  {1, -1},    -- col 2 (a12, a22)
  {3, 0}      -- RHS  (b1,  b2)
}
local sol, err = gauss_jordan_cols(aug)
-- sol -> {1, 1}  (if system solvable)
]]


--- point_line_segment_occlusion_sort
--- @param P table<table<number>> the point
--- @param L table<table<number>> the line
--- @return true|false|nil depth relationship
local function point_line_segment_occlusion_sort(P, L)
    local line_origin = { L[1] }
    local line_direction_vector = vector_subtraction( { L[2] }, { L[1] } )
    -- The line has affine basis {line_origin, line_direction_vector}
    local point_from_the_lines_origin = vector_subtraction( P, { L[1] } )
    local projection = orthogonal_vector_projection(
        line_direction_vector,
        point_from_the_lines_origin
    )
    local true_projection = vector_addition(
        line_origin,
        projection
    )
    -- We orthogonally project the point onto the line segment.

    --[[
        If the xy-projections of the point and true_projection are
        close, then proceed. Otherwise, they do not occlude one another.
    ]]
    local F = {{P[1][1], P[1][2], 0, 1}}
    local G = {{true_projection[1][1], true_projection[1][2], 0, 1}}
    if distance(F, G) < 0.0000001 then
        local tmp
        if (
            sign(projection[1][1]) == sign(line_direction_vector[1][1]) and
            sign(projection[1][2]) == sign(line_direction_vector[1][2]) and
            sign(projection[1][3]) == sign(line_direction_vector[1][3])
        ) then 
            tmp = 1
        else 
            tmp = -1
        end
        local test = tmp * length(projection) / length(line_direction_vector)
        if (0<=test and test<=1) then
            return point_point_occlusion_sort(P, true_projection)
        end
    end
    return nil
end




local function point_triangle_occlusion_sort(P, T)

    --[[
        First we project the point and the triangle onto the
        viewing plane (xy). We do this to determine if they occluse 
        using a cross product test. If they do, then we vertically 
        project the point onto the triangle and compare by that.
    ]]
    local point_projection = { {P[1][1], P[1][2], 0, 1} }
    local T1_projection = { {T[1][1], T[1][2], 0, 1} }
    local T2_projection = { {T[2][1], T[2][2], 0, 1} }
    local T3_projection = { {T[3][1], T[3][2], 0, 1} }

    local dist1 = distance(P, {T[1]})
    local dist2 = distance(P, {T[2]})
    local dist3 = distance(P, {T[3]})

    --[[
        For reasons of space, we will invoke smaller names
        for our points.
    ]]
    local P1 = point_projection
    local T1 = T1_projection
    local T2 = T2_projection
    local T3 = T3_projection

    local T1T2 = vector_subtraction(T2, T1)
    local T1P1 = vector_subtraction(P1, T1)
    local T1T2xT1P1 = cross_product(T1T2, T1P1)
    local sign_T1T2xT1P1 = sign(T1T2xT1P1[1][3])

    local T2T3 = vector_subtraction(T3, T2)
    local T2P1 = vector_subtraction(P1, T2)
    local T2T3xT2P1 = cross_product(T2T3, T2P1)
    local sign_T2T3xT2P1 = sign(T2T3xT2P1[1][3])

    local T3T1 = vector_subtraction(T1, T3)
    local T3P1 = vector_subtraction(P1, T3)
    local T3T1xT3P1 = cross_product(T3T1, T3P1)
    local sign_T3T1xT3P1 = sign(T3T1xT3P1[1][3])

    local tmp = (dist1 > 0.0000001 and dist2 > 0.0000001 and dist3 > 0.0000001)
    --if not tmp then return false end
    if (
        sign_T1T2xT1P1 == sign_T2T3xT2P1 and 
        sign_T2T3xT2P1 == sign_T3T1xT3P1 and tmp
    ) then 
        local o = {T[1]}
        local u = vector_subtraction({T[2]}, {T[1]})
        local v = vector_subtraction({T[3]}, {T[1]})
        local augmented_matrix = {
            {u[1][1], u[1][2]} -- t
            ,{v[1][1], v[1][2]} -- s
            ,{P[1][1]-o[1][1], P[1][2]-o[1][2]} -- t+s
        }
        local sol = gauss_jordan_cols(augmented_matrix)
        local t, s
        if sol then 
            t = sol[1]
            s = sol[2]
        end
        if t == nil or s == nil then return nil end
        if 0<=t and t<=1 and 0<=s and s<=1 then 
            local a = vector_addition(o, scalar_multiplication(t, u))
            local b = vector_addition(a, scalar_multiplication(s, v))
            return point_point_occlusion_sort(P, b)
        end
    end
    return nil
end






local function line_segment_line_segment_occlusion_sort(L1, L2)
    local L1A, L1B = {{L1[1][1], L1[1][2], 0, 1}}, {{L1[2][1], L1[2][2], 0, 1}}
    local L2A, L2B = {{L2[1][1], L2[1][2], 0, 1}}, {{L2[2][1], L2[2][2], 0, 1}}
    local L1_dir = vector_subtraction(L1B, L1A)
    local L2_dir = vector_subtraction(L2B, L2A)
    if length(cross_product(L1_dir,L2_dir)) > 0 then
        --[=[ 
            L1A + (t)*L1_dir = L2A + (s)*L2_dir -->...
            ...--> [(t)*L1_dir] - [(s)*L2_dir] = [L2A - L1A]
        ]=]
        local augmented_matrix = {
            {L1_dir[1][1], L1_dir[1][2]}, --> t
            {-L2_dir[1][1], -L2_dir[1][2]}, --> s
            {L2A[1][1]-L1A[1][1], L2A[1][2]-L1A[1][2]} --> t+s
        }
        local sol = gauss_jordan_cols(augmented_matrix)
        local t, s
        if sol then 
            t = sol[1]
            s = sol[2]
        end
        if t == nil or s == nil then return nil end
        if (0 <= t and t<=1 and 0 <= s and s <= 1) then
            local L1_inverse = vector_addition({L1[1]}, scalar_multiplication(t, vector_subtraction({L1[2]}, {L1[1]})))
            local L2_inverse = vector_addition({L2[1]}, scalar_multiplication(s, vector_subtraction({L2[2]}, {L2[1]})))
            return point_point_occlusion_sort(L1_inverse, L2_inverse)
        end
    else 
        --return point_point_occlusion_sort({L1[1]}, {L2[1]})
        local M1 = point_line_segment_occlusion_sort({L1[1]}, L2)
        local M2 = point_line_segment_occlusion_sort({L1[2]}, L2)
        local M3 = point_line_segment_occlusion_sort({L2[1]}, L1)
        if M3 ~= nil then M3 = not M3 end
        local M4 = point_line_segment_occlusion_sort({L2[2]}, L1)
        if M4 ~= nil then M4 = not M4 end
        if (M1 == true or M2 == true or M3 == true or M4 == true) then 
            return true 
        end
        if (M1 == false or M2 == false or M3 == false or M4 == false) then 
            return false 
        end
    end
    return nil
end

local function line_segment_triangle_occlusion_sort(L, T)
    local A = point_triangle_occlusion_sort({L[1]}, T)
    local B = point_triangle_occlusion_sort({L[2]}, T)
    local T1, T2, T3 = {T[1], T[2]}, {T[2], T[3]}, {T[3], T[1]}
    local C = line_segment_line_segment_occlusion_sort(L, T1)
    local D = line_segment_line_segment_occlusion_sort(L, T2)
    local E = line_segment_line_segment_occlusion_sort(L, T3)
    if (
        A == true or
        B == true or
        C == true or
        D == true or
        E == true
    ) then 
        return true 
    end 
    if (
        A == false or
        B == false or
        C == false or
        D == false or
        E == false
    ) then 
        return false 
    end
    return nil
end

local function triangle_triangle_occlusion_sort(T1, T2)

    local T1AB, T1BC, T1CA = {T1[1],T1[2]}, {T1[2],T1[3]}, {T1[3],T1[1]}
    local A = line_segment_triangle_occlusion_sort(T1AB, T2)
    local B = line_segment_triangle_occlusion_sort(T1BC, T2)
    local C = line_segment_triangle_occlusion_sort(T1CA, T2)
    if (
        A == true or
        B == true or
        C == true
    ) then 
        return true 
    end 
    if (
        A == false or
        B == false or
        C == false
    ) then 
        return false 
    end


    local D = point_triangle_occlusion_sort({T1[1]}, T2)
    local E = point_triangle_occlusion_sort({T1[2]}, T2)
    local F = point_triangle_occlusion_sort({T1[3]}, T2)

    local G = point_triangle_occlusion_sort({T2[1]}, T1)
    local H = point_triangle_occlusion_sort({T2[2]}, T1)
    local I = point_triangle_occlusion_sort({T2[3]}, T1)

    if (
        D == true or
        E == true or
        F == true or 
        G == false or 
        H == false or 
        I == false
    ) then 
        return true 
    end 
    if (
        D == false or
        E == false or
        F == false or 
        G == true or 
        H == true or 
        I == true
    ) then 
        return false 
    end

    return nil
end


--- Occlusion sorts an arbitrary set of segments.
--- @param S1 table<table<number>> a segment
--- @param S2 table<table<number>> another segment
--- @return boolean or nil
local function occlusion_sort_segments(S1, S2)
    if (S1.type == "point" and S2.type == "point") then
        return point_point_occlusion_sort(S1.segment, S2.segment)
    elseif (S1.type == "point" and S2.type == "line segment") then
        return point_line_segment_occlusion_sort(S1.segment, S2.segment)
    elseif (S1.type == "point" and S2.type == "triangle") then 
        return point_triangle_occlusion_sort(S1.segment, S2.segment)
    elseif (S1.type == "line segment" and S2.type == "point") then 
        local ans = point_line_segment_occlusion_sort(S2.segment, S1.segment)
        if ans == nil then return nil end 
        return not ans
    elseif (S1.type == "line segment" and S2.type == "line segment") then 
        return line_segment_line_segment_occlusion_sort(S1.segment, S2.segment)
    elseif (S1.type == "line segment" and S2.type == "triangle") then 
        return line_segment_triangle_occlusion_sort(S1.segment, S2.segment)
    elseif (S1.type == "triangle" and S2.type == "point") then
        local ans = point_triangle_occlusion_sort(S2.segment, S1.segment)
        if ans == nil then return nil end 
        return not ans
    elseif (S1.type == "triangle" and S2.type == "line segment") then 
        local ans = line_segment_triangle_occlusion_sort(S2.segment, S1.segment)
        if ans == nil then return nil end 
        return not ans
    elseif (S1.type == "triangle" and S2.type == "triangle") then
        return triangle_triangle_occlusion_sort(S1.segment, S2.segment)
    end
end

return occlusion_sort_segments


