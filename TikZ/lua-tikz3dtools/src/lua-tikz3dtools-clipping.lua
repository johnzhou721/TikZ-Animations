-- lua-tikz3dtools-clipping.lua

--[[
    - main clipping algorithm
    -- line segment-line segment clip
    -- line segment-triangle clip
    -- triangle-triangle clip
    - cyclic occlusion clip (we do this only if a cycle exists)
    -- for line segments
    -- for line segments and triangles
    -- for triangles
]]

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

local function line_segment_line_segment_clip(L1, L2)
    local L1A, L1D = {L1[1]}, vector_subtraction({L1[2]}, {L1[1]})
    local L2A, L2D = {L2[1]}, vector_subtraction({L2[2]}, {L2[1]})
    if 
    --[[
        L1A + (t)*L1D = L2A + (s)*L2D
        (t)*L1D - (s)*L2D = L2A - L1A
    ]]
    local rhs = vector_subtraction(L2A, L1A)
    local augmented_matrix = {
        {L1D[1][1], L1D[1][2], L1D[1][3]}
        ,{L2D[1][1], L2D[1][2], L2D[1][3]}
        ,{rhs[1][1], rhs[1][2], rhs[1][3]}
    }
end