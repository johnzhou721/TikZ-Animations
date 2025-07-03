-- matrix math.lua

local mm = {}

cos   = math.cos
acos  = math.acos
sin   = math.sin
asin  = math.asin
tan   = math.tan
atan  = math.atan
atan2 = math.atan2
sqrt  = math.sqrt 
min   = math.min 
max   = math.max 
abs   = math.abs
pi    = math.pi 
tau   = 2*pi

--- matrix multiplication
---
--- @param A table<table<number>> left matrix
--- @param B table<table<number>> right matrix
--- @return table<table<number>> the product
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

function y_rotation_3D(angle)
    local c = cos(angle)
    local s = sin(angle)
    return {
        {c,0,s,0}
        ,{0,1,0,0}
        ,{-s,0,c,0}
        ,{0,0,0,1}
    }
end

function z_rotation_3D(angle)
    local c = cos(angle)
    local s = sin(angle)
    return {
        {c,s,0,0}
        ,{-s,c,0,0}
        ,{0,0,1,0}
        ,{0,0,0,1}
    }
end

function euler(alpha,beta,gamma)
    return matrix_multiply(
        z_rotation_3D(gamma)
        ,matrix_multiply(
            y_rotation_3D(beta)
            ,z_rotation_3D(alpha)
        )
    )
end

function sphere(longitude,latitude)
    local s = sin(latitude)
    return {{
        s * cos(longitude)
        ,s * sin(longitude)
        ,cos(latitude)
        ,1
    }}
end