-- File saved as linalg.lua
la = {}
la.pi = 3.14159265358979


--[[
    Inner product
]]
function la.inner(v1,v2)
    assert(#v1 == #v2, "Inner product works only on same size vectors.")
    local a = {}
    for component = 1, #v1 - 1, 1 do
        table.insert(a,v1[component])
    end
    local b = {}
    for component = 1, #v2 - 1, 1 do
        table.insert(b,v2[component])
    end
    local result = 0
    for component_pos = 1, #a, 1 do
        result = result + a[component_pos]*b[component_pos]
    end
    return result
end

--[[
    Cross product in \(\mathbb{R}^{3}\)
    Will make n-dimensional at some point, I think.
]]
function la.cross(vectors)
    assert(#vectors == 2, "Cross product in R3 takes two vectors.")
    local v1 = {}
    for component = 1, #vectors[1] - 1, 1 do
        table.insert(v1,vectors[1][component])
    end
    local v2 = {}
    for component = 1, #vectors[2] - 1, 1 do
        table.insert(v2,vectors[2][component])
    end
    return {
        v1[2]*v2[3] - v1[3]*v2[2]
        ,v1[3]*v2[1] - v1[1]*v2[3]
        ,v1[1]*v2[2] - v1[2]*v2[1]
    }
end

--[[]]
function la.point_unique(point)
    local result = {}
    for component = 1, #point, 1 do
        result[component] = point[component]/point[#point]
    end
    return result
end

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
    Inverse matrix
]]
function la.inverse(matrix)
    rows = #matrix
    columns = #matrix[1]
    assert(rows == columns, "You can only take the inverse of a square matrix.")
    assert(la.det(matrix)>0.00001, "You cannot take the inverse of a singular matrix")

end


--[[ 
    Determinant
]]
function la.det(matrix)
    local rows = #matrix
    local columns = #matrix[1]
    assert(rows > 0, "Matrix must have at least one row to take determinant.")
    assert(columns > 0, "Matrix must have at least one column to take determinant.")
    assert(rows == columns, "You can only take the determinant of a square matrix.")
    if rows == 1 then
        return matrix[1][1]
    elseif rows == 2 then
        -- return a*d - b*c
        return matrix[1][1] * matrix[2][2] - matrix[1][2] * matrix[2][1]
    end
    -- We will do a cofactor expansion on the first row.
    local det = 0
    local minor
    local new_row
    for element = 1, columns, 1 do
        minor = {}
        for row = 2, rows, 1 do
            new_row = {}
            for column = 1, columns, 1 do
                if column ~= element then
                    table.insert(new_row, matrix[row][column])
                end
            end
            table.insert(minor,new_row)
        end
        det = det + matrix[1][element] * (-1)^(element+1) * la.det(minor)
    end
    return det
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

function la.XYZscale3D(xscale,yscale,zscale)
    return {
        {xscale,0,0,0}
        ,{0,yscale,0,0}
        ,{0,0,zscale,0}
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

--[[
    ZYZ Euler angle rotation matrix
]]
function la.ZYZrotation3D(alpha,beta,gamma)
    return la.mult(
        la.zrotation3D(gamma)
        ,la.mult(
            la.yrotation3D(alpha)
            ,la.zrotation3D(beta)
        )
    )
end

function la.sphere(longitude,latitude)
    return {
        math.cos(latitude) * math.cos(longitude)
        ,math.cos(latitude) * math.sin(longitude)
        ,math.sin(latitude)
        ,1
    }
end

return la -- ends file