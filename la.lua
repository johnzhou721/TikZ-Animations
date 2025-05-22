-- File saved as la.lua
la = {}
la.pi = 3.14159265358979


--[[
    Inner product
]]
function la.inner(v1,v2)
    assert(#v1 == #v2, "Inner product works only on same size vectors.")
    local result = 0
    for component_pos = 1, #v1[1], 1 do
        result = result + v1[1][component_pos]*v2[1][component_pos]
    end
    return result
end

--[[
    Cross product in \(\mathbb{R}^{3}\)
    Will make n-dimensional at some point, I think.
]]
function la.cross(v1,v2)
    return {{
        v1[1][2]*v2[1][3] - v1[1][3]*v2[1][2]
        ,v1[1][3]*v2[1][1] - v1[1][1]*v2[1][3]
        ,v1[1][1]*v2[1][2] - v1[1][2]*v2[1][1]
        ,1
    }}
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
            sum[row][column] = A[row][column] - B[row][column]
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

--[[
    Three dimensional translation
]]
function la.translate3D(x,y,z)
    return {
        {1,0,0,0}
        ,{0,1,0,0}
        ,{0,0,1,0}
        ,{x,y,z,1}
    }
end

function la.sphere(longitude,latitude)
    return {{
        math.cos(latitude) * math.cos(longitude)
        ,math.cos(latitude) * math.sin(longitude)
        ,math.sin(latitude)
        ,1
    }}
end