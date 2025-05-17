-- File saved as linalg.lua
local la = {}

--[[
    Matrix addition
]]
function la.add(A, B)
    local rows_A = #A
    local columns_A = #A[1]
    local rows_B = #B
    local columns_B = #B[1]
    assert(rows_A == rows_B and columns_A == columns_B, "Wrong size matrices for addition.")
    local sum = {}
    for row = 1, rows_A do
        sum[row] = {}
        for column = 1, columns_A do
            sum[row][column] = A[row][column] + B[row][column]
        end
    end
    return sum
end



return la -- ends file