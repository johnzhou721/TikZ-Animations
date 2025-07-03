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
        {c,0,-s,0}
        ,{0,1,0,0}
        ,{s,0,c,0}
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

function mm.matrix_add(A, B)
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

function mm.matrix_subtract(A,B)
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

function mm.matrix_scale(factor, A)
    local rows = #A
    local cols = #A[1]
    local result = {}
    for i = 1, rows do
        result[i] = {}
        for j = 1, cols do
            result[i][j] = A[i][j] * factor
        end
    end
    return result
end

function mm.sign(number)
    if number >= 0 then return "positive" end
    return "negative"
end

function mm.dot_product(u,v)
    local result = u[1][1]*v[1][1] + u[1][2]*v[1][2] + u[1][3]*v[1][3]
    return result
end

function mm.cross_product(u,v)
    local x = u[1][2]*v[1][3]-u[1][3]*v[1][2]
    local y = u[1][3]*v[1][1]-u[1][1]*v[1][3]
    local z = u[1][1]*v[1][2]-u[1][2]*v[1][1]
    local result = {{x,y,z,1}}
    return result
end

function mm.norm(u)
    local result = math.sqrt((u[1][1])^2 + (u[1][2])^2 + (u[1][3])^2)
    return result
end

function mm.normalize(vector)
    local len = mm.norm(vector)
    return {{
        vector[1][1]/len
        ,vector[1][2]/len
        ,vector[1][3]/len
        ,1
    }}
end

function mm.midpoint(triangle)
    local P,Q,R = table.unpack(triangle)
    local x = (P[1]+Q[1]+R[1])/3
    local y = (P[2]+Q[2]+R[2])/3
    local z = (P[3]+Q[3]+R[3])/3
    return {{x,y,z,1}}
end

function mm.orthogonal_vector(u)
    local v
    if (u[1][1]~=0 and u[1][2]==0 and u[1][3]==0) then
        v = mm.cross_product(u,{{0,1,0,1}})
    else
        v = mm.cross_product(u,{{1,0,0,1}})
    end
    return v
end

function mm.get_observer_plane_basis(observer)
    local origin = {{0,0,0,1}}
    local basis_i = mm.orthogonal_vector(observer)
    basis_i = mm.normalize(basis_i)
    local basis_j = mm.cross_product(observer,basis_i)
    basis_j = mm.normalize(basis_j)
    return {origin,basis_i,basis_j}
end

function mm.orthogonal_vector_projection(base_vector,projected_vector)
    local scale = (
        mm.dot_product(base_vector,projected_vector) / 
        mm.dot_product(base_vector,base_vector)
    )
    return {{base_vector[1][1]*scale,base_vector[1][2]*scale,base_vector[1][3]*scale,1}}
end

function mm.project_point_onto_basis(point,basis)
    local normal = mm.cross_product(basis[2],basis[3])
    normal = mm.normalize(normal)
    local vector_from_plane = mm.orthogonal_vector_projection(point,normal)
    local result = {{
        point[1][1]-vector_from_plane[1][1]
        ,point[1][2]-vector_from_plane[1][2]
        ,point[1][3]-vector_from_plane[1][3]
        ,1
    }}
    return result
end


return mm