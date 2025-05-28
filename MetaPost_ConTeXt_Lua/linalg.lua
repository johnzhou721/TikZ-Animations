-- File saved as linalg.lua
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
    return {{
        math.cos(latitude) * math.cos(longitude)
        ,math.cos(latitude) * math.sin(longitude)
        ,math.sin(latitude)
        ,1
    }}
end


--[[ 
    Generate an n×n identity matrix 
]]
local function identity_matrix(n)
    local I = {}
    for i = 1, n do
        I[i] = {}
        for j = 1, n do
            I[i][j] = (i == j) and 1 or 0
        end
    end
    return I
end

--[[
    Decompose a square, invertible matrix A into a product of elementary matrices:
    A = E1 * E2 * ... * Ek

    We perform Gauss–Jordan elimination on a copy of A, keeping track of each
    row operation.  For each operation (swap, scale, row‐addition), we determine
    its inverse elementary matrix and append it to the list.  In the end,

        E₁⁻¹, E₂⁻¹, …, Eₖ⁻¹  were recorded in that order, so

        A = E₁⁻¹ * E₂⁻¹ * … * Eₖ⁻¹.

    Returns an array `elem_list` of elementary matrices (each itself an n×n Lua table).
]]
function la.decompose(A)
    local n = #A
    assert(n > 0 and #A[1] == n, "Matrix must be nonempty and square for decomposition.")
    -- Deep copy A into M
    local M = {}
    for i = 1, n do
        M[i] = {}
        for j = 1, n do
            M[i][j] = A[i][j]
        end
    end

    local epsilon = 1e-12
    local elem_list = {}  -- will hold the inverse elementary matrices in order

    for i = 1, n do
        -- 1) If pivot M[i][i] is (nearly) zero, swap with a lower row that has a nonzero in column i
        if math.abs(M[i][i]) < epsilon then
            local swap_row = nil
            for r = i + 1, n do
                if math.abs(M[r][i]) > epsilon then
                    swap_row = r
                    break
                end
            end
            assert(swap_row, "Matrix is singular; cannot decompose.")
            -- Build the elementary swap matrix P that swaps rows i and swap_row
            local P = identity_matrix(n)
            P[i], P[swap_row] = P[swap_row], P[i]  -- just swap those two rows in the identity
            -- Apply P to M:  M ← P * M
            M = la.mult(P, M)
            -- A swap is its own inverse, so P is also P⁻¹.  Append it to elem_list.
            table.insert(elem_list, P)
        end

        -- 2) Scale row i so that M[i][i] becomes 1
        local pivot = M[i][i]
        assert(math.abs(pivot) > epsilon, "Pivot cannot be zero after swapping.")
        if math.abs(pivot - 1) > epsilon then
            -- E_scale will divide row i by `pivot`
            local E_scale = identity_matrix(n)
            E_scale[i][i] = 1 / pivot
            -- Apply to M:
            M = la.mult(E_scale, M)
            -- Its inverse is "multiply row i by pivot"
            local E_scale_inv = identity_matrix(n)
            E_scale_inv[i][i] = pivot
            table.insert(elem_list, E_scale_inv)
        end
        -- Now M[i][i] == 1

        -- 3) For every other row r ≠ i, eliminate the entry in column i
        for r = 1, n do
            if r ~= i then
                local factor = M[r][i]
                if math.abs(factor) > epsilon then
                    -- Build the elimination matrix E_elim that does: row_r ← row_r − factor * row_i
                    local E_elim = identity_matrix(n)
                    E_elim[r][i] = -factor
                    -- Apply to M:
                    M = la.mult(E_elim, M)
                    -- Inverse of that is: row_r ← row_r + factor * row_i
                    local E_elim_inv = identity_matrix(n)
                    E_elim_inv[r][i] = factor
                    table.insert(elem_list, E_elim_inv)
                end
            end
        end
        -- At this point, column i is now 0 everywhere except M[i][i] = 1
    end

    -- If everything went well, M is now the identity matrix.
    -- The list elem_list = {E₁, E₂, …, Eₖ} holds exactly those inverses of
    -- the elimination‐step matrices, in the order they must multiply to recover A.
    return elem_list
end


return la -- ends file