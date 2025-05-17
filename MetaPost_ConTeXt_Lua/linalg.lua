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
    for row = 1, rows_A, 1 do
        sum[row] = {}
        for column = 1, columns_A, 1 do
            sum[row][column] = A[row][column] + B[row][column]
        end
    end
    return sum
end

--[[
    Matrix scalar multiplication
]]
function la.scale(a,A)
    local rows_A = #A
    local columns_A = #A[1]
    local product = {}
    for row = 1, rows_A, 1 do
        product[row] = {}
        for column = 1, columns_A, 1 do
            product[row][column] = a * A[row][column]
        end
    end
    return product
end

--[[
    Matrix subtraction
]]
function la.sub(A,B)
    local rows_A = #A
    local columns_A = #A[1]
    local rows_B = #B
    local columns_B = #B[1]
    assert(rows_A == rows_B and columns_A == columns_B, "Wrong size matrices for subtraction.")
    local sum = {}
    for row = 1, rows_A, 1 do
        sum[row] = {}
        for column = 1, columns_A, 1 do
            sum[row][column] = A[row][column] + la.scale(-1,B[row][column])
        end
    end
    return sum
end

--[[
    Matrix multiplication
]]
function la.mult(A,B)
    local rows_A = #A
    local columns_A = #A[1]
    local rows_B = #B
    local columns_B = #B[1]
    assert(columns_A == rows_B, "Wrong size matrices for multiplication.")
    local product = {}
    for row = 1, rows_A, 1 do
        product[row] = {}
        for column = 1, columns_B, 1 do
            product[row][column] = 0
            for dot_product_step = 1, columns_A, 1 do
                product[row][column] = product[row][column] + A[row][dot_product_step] * B[dot_product_step][column]
            end
        end
    end
    return product
end



return la -- ends file