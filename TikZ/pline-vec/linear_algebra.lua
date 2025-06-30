-- File saved as linear_algebra.lua
local la = {}
la.tau = 2 * math.pi

--[[
    Normalize a vector.
    For homogeneous coordinates, we leave the last component unchanged.
    We assume the vector is a 1-row matrix, i.e. {{x, y, z, w}}.
]]
function la.normalize(v)
    local vec = v[1]
    local n = #vec
    local last = vec[n]
    local length_squared = 0
    for i = 1, n - 1 do
        length_squared = length_squared + vec[i]^2
    end
    local length = math.sqrt(length_squared)
    assert(length > 0, "Cannot normalize a zero-length vector.")

    local result = {}
    for i = 1, n - 1 do
        result[i] = vec[i] / length
    end
    result[n] = last
    return {result}
end

function la.norm(v)
    local length = math.sqrt((v[1][1])^2+(v[1][2])^2+(v[1][3])^2)
    return length
end

function la.sign(number)
    if number >= 0 then return "positive" end
    return "negative"
end
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
    Midpoint
]]
function la.midpoint(seg)
    if #seg == 2 then
        local avgx = (seg[1][1][1] + seg[2][1][1]) / 2
        local avgy = (seg[1][1][2] + seg[2][1][2]) / 2
        local avgz = (seg[1][1][3] + seg[2][1][3]) / 2
        return {{avgx,avgy,avgz,1}}
    elseif #seg == 3 then 
        local avgx = (seg[1][1][1] + seg[2][1][1]  + seg[3][1][1]) / 3
        local avgy = (seg[1][1][2] + seg[2][1][2]  + seg[3][1][2]) / 3
        local avgz = (seg[1][1][3] + seg[2][1][3]  + seg[3][1][3]) / 3
        return {{avgx,avgy,avgz,1}}
    else
        assert(false, "Can't calculate midpoint.")
    end
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
function la.is_valid_w(matrix)
        if math.abs(matrix[1][4]) <= 0.005 then
            return false
        end
    return true
end

function la.reciprocate_by_homogenous(matrix)
    local result = {}
    for i = 1, #matrix do
        local row = matrix[i]
        local w = row[4]
        if w == 0 then
            error("Cannot reciprocate row " .. i .. ": homogeneous coordinate w = 0")
        end
        --if w<0 then w=-w end
        result[i] = {
            row[1]/w,
            row[2]/w,
            row[3]/w,
            1
        }
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
    Inverse matrix (using Gauss-Jordan elimination, row‐vector convention)
]]
function la.inverse(matrix)
    local rows = #matrix
    local columns = #matrix[1]
    assert(rows == columns, "You can only take the inverse of a square matrix.")
    local det = la.det(matrix)
    assert(math.abs(math.abs(det)) > 0.00001, "You cannot take the inverse of a singular matrix.")

    local n = rows
    -- Build an augmented matrix [A | I]
    local augment = {}
    for i = 1, n do
        augment[i] = {}
        -- copy row i of A
        for j = 1, n do
            augment[i][j] = matrix[i][j]
        end
        -- append row i of I
        for j = 1, n do
            augment[i][n + j] = (i == j) and 1 or 0
        end
    end

    -- Gauss-Jordan elimination
    for i = 1, n do
        -- If pivot is zero (or very close), swap with a lower row that has a nonzero pivot
        if math.abs(augment[i][i]) < 1e-12 then
            local swapRow = nil
            for r = i + 1, n do
                if math.abs(augment[r][i]) > 1e-12 then
                    swapRow = r
                    break
                end
            end
            assert(swapRow, "Matrix is singular (zero pivot encountered).")
            augment[i], augment[swapRow] = augment[swapRow], augment[i]
        end

        -- Normalize row i so that augment[i][i] == 1
        local pivot = augment[i][i]
        for col = 1, 2 * n do
            augment[i][col] = augment[i][col] / pivot
        end

        -- Eliminate column i in all other rows
        for r = 1, n do
            if r ~= i then
                local factor = augment[r][i]
                for col = 1, 2 * n do
                    augment[r][col] = augment[r][col] - factor * augment[i][col]
                end
            end
        end
    end

    -- Extract the inverse matrix from the augmented result
    local inv = {}
    for i = 1, n do
        inv[i] = {}
        for j = 1, n do
            inv[i][j] = augment[i][n + j]
        end
    end

    return inv
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
        ,{math.cos(angle+la.tau/4),math.sin(angle+la.tau/4),0}
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

-- Element-wise scalar multiplication of a matrix
function la.scale(factor, A)
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
        {math.cos(angle),0,math.sin(angle),0}
        ,{0,1,0,0}
        ,{-math.sin(angle),0,math.cos(angle),0}
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
function la.euler(alpha,beta,gamma)
    return la.mult(
        la.zrotation3D(gamma)
        ,la.mult(
            la.yrotation3D(beta)
            ,la.zrotation3D(alpha)
        )
    )
end

function la.sphere(longitude,latitude)
    return {{
        math.sin(latitude) * math.cos(longitude)
        ,math.sin(latitude) * math.sin(longitude)
        ,math.cos(latitude)
        ,1
    }}
end


--[[ 
    Generate a homogeneous identity matrix 
]]
function la.identity(n)
    local n = n+1
    local I = {}
    for i = 1, n do
        I[i] = {}
        for j = 1, n do
            I[i][j] = (i == j) and 1 or 0
        end
    end
    return I
end





return la -- ends file