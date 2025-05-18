-- File saved as linalg.lua
la = {}
la.pi = 3.14159265358979
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
    Matrix transpose
]]
function  la.transpose(A)
    local rows_A = #A
    local columns_A = #A[1]
    local result = {}
    for row = 1, columns_A, 1 do
        result[row] = {}
        for column = 1, rows_A, 1 do
            result[row][column] = A[column][row]
        end
    end
    return result
end

--[[
    2D counterclockwise rotation about origin.
    It is a 3x3 matrix because it uses homogeneous coordinates.
]]
function la.rotate2D(angle)
    return {
        {math.cos(angle),math.sin(angle),0}
        ,{math.cos(angle+la.pi/2),math.sin(angle+la.pi/2),0}
        ,{0,0,1}
    }
end


--[[
    Homogeneous matrix for 2D translation
]]
function la.translate2D(x,y)
    return {
        {1,0,0}
        ,{0,1,0}
        ,{x,y,1}
    }
end



--[[
    Three dimensional scaling.
]]

function la.xscale3D(scale)
    return {
        {scale,0,0,0}
        ,{0,1,0,0}
        ,{0,0,1,0}
        ,{0,0,0,1}
    }
end

function la.yscale3D(scale)
    return {
        {1,0,0,0}
        ,{0,scale,0,0}
        ,{0,0,1,0}
        ,{0,0,0,1}
    }
end

function la.zscale3D(scale)
    return {
        {1,0,0,0}
        ,{0,1,0,0}
        ,{0,0,scale,0}
        ,{0,0,0,1}
    }
end

function la.scale3D(scale)
    return {
        {scale,0,0,0}
        ,{0,scale,0,0}
        ,{0,0,scale,0}
        ,{0,0,0,1}
    }
end

function la.xrotation3D(angle)
    return {
        {1,0,0,0}
        ,{0,math.cos(angle),math.sin(angle),0}
        ,{0,-math.sin(angle),math.cos(angle),0}
        ,{0,0,0,1}
    }
end

function la.yrotation3D(angle)
    return {
        {math.cos(angle),0,-math.sin(angle),0}
        ,{0,1,0,0}
        ,{math.sin(angle),0,math.cos(angle),0}
        ,{0,0,0,1}
    }
end

function la.zrotation3D(angle)
    return {
        {math.cos(angle),math.sin(angle),0,0}
        ,{-math.sin(angle),math.cos(angle),0,0}
        ,{0,0,1,0}
        ,{0,0,0,1}
    }
end

function ZYZrotation3D(alpha,beta,gamma)
    return la.mult(
        la.mult(
            la.zrotation3D(alpha)
            ,la.yrotation3D(beta)
        )
        ,la.zrotation3D(gamma)
    )
end


return la -- ends file