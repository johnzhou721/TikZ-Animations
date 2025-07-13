-- tikz-lua3dtools-matrix-math.lua

local mm = {}
mm.tau = 2*math.pi 

local cos, sin = math.cos, math.sin

--- matrix multiplication
---
--- @param A table<table<number>> left matrix
--- @param B table<table<number>> right matrix
--- @return table<table<number>> the product
function mm.matrix_multiply(A, B)
    local rows_A = #A
    local columns_A = #A[1]
    local rows_B = #B
    local columns_B = #B[1]
    assert(
        columns_A == rows_B,
        string.format(
            [[
                Wrong size matrices for multiplication.
                Size A: %d,%d Size B: %d,%d
            ]],
            rows_A, columns_A,
            rows_B, columns_B
        )
    )
    local product = {}
    for row = 1, rows_A do
        product[row] = {}
        for column = 1, columns_B do
            product[row][column] = 0
            for dot_product_step = 1, columns_A do
                local a = A[row][dot_product_step]
                local b = B[dot_product_step][column]
                assert(type(a) == "number", 
                    string.format("Expected number but got %s in A[%d][%d]", type(a), row, dot_product_step))
                assert(type(b) == "number", 
                    string.format("Expected number but got %s in B[%d][%d]", type(b), dot_product_step, column))
                product[row][column] = product[row][column] + a * b
            end
        end
    end
    return product
end

function mm.reciprocate_by_homogenous(vector)
    local result = {}
    for i = 1, #vector do
        local row = vector[i]
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

function  mm.transpose(A)
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

function mm.inverse(matrix)
    local rows = #matrix
    local columns = #matrix[1]
    assert(rows == columns, "You can only take the inverse of a square matrix.")
    local det = mm.det(matrix)
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

function mm.det(matrix)
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
        det = det + matrix[1][element] * (-1)^(element+1) * mm.det(minor)
    end
    return det
end

function mm.yrotation(angle)
    local c = cos(angle)
    local s = sin(angle)
    return {
        {c,0,-s,0}
        ,{0,1,0,0}
        ,{s,0,c,0}
        ,{0,0,0,1}
    }
end

function mm.translate(x,y,z)
    return {
        {1,0,0,0}
        ,{0,1,0,0}
        ,{0,0,1,0}
        ,{x,y,z,1}
    }
end

function mm.xscale(scale)
    return {
        {scale,0,0,0}
        ,{0,1,0,0}
        ,{0,0,1,0}
        ,{0,0,0,1}
    }
end

function mm.yscale(scale)
    return {
        {1,0,0,0}
        ,{0,scale,0,0}
        ,{0,0,1,0}
        ,{0,0,0,1}
    }
end

function mm.zscale(scale)
    return {
        {1,0,0,0}
        ,{0,1,0,0}
        ,{0,0,scale,0}
        ,{0,0,0,1}
    }
end

function mm.scale(scale)
    return {
        {scale,0,0,0}
        ,{0,scale,0,0}
        ,{0,0,scale,0}
        ,{0,0,0,1}
    }
end

function mm.xrotation(angle)
    return {
        {1,0,0,0}
        ,{0,math.cos(angle),math.sin(angle),0}
        ,{0,-math.sin(angle),math.cos(angle),0}
        ,{0,0,0,1}
    }
end


function mm.zrotation(angle)
    local c = cos(angle)
    local s = sin(angle)
    return {
        {c,s,0,0}
        ,{-s,c,0,0}
        ,{0,0,1,0}
        ,{0,0,0,1}
    }
end

function mm.euler(alpha,beta,gamma)
    return mm.matrix_multiply(
        mm.zrotation(gamma)
        ,mm.matrix_multiply(
            mm.yrotation(beta)
            ,mm.zrotation(alpha)
        )
    )
end

function mm.sphere(longitude,latitude)
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

function mm.identity_matrix()
    local I = {}
    for i = 1, 4 do
        I[i] = {}
        for j = 1, 4 do
            I[i][j] = (i == j) and 1 or 0
        end
    end
    return I
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

function mm.stereographic_projection(point)
    local x = point[1][1]
    local y = point[1][2]
    local z = point[1][3]
    return {{x / (1 - z), y / (1 - z), 0, 1}}
end

function mm.clip_triangle_against_line(triangle, line)
    -- triangle: array of 3 points {{x,y,z}, {x,y,z}, {x,y,z}}
    -- line: two points defining a 3D line {{x,y,z}, {x,y,z}}

    local function point_on_side(p, line)
        -- Determine signed distance of point p to the infinite line
        -- using vector cross product magnitude with line direction vector

        local function vector_sub(a,b)
            return {a[1]-b[1], a[2]-b[2], a[3]-b[3]}
        end

        local function cross(u,v)
            return {
                u[2]*v[3] - u[3]*v[2],
                u[3]*v[1] - u[1]*v[3],
                u[1]*v[2] - u[2]*v[1],
            }
        end

        local function dot(u,v)
            return u[1]*v[1] + u[2]*v[2] + u[3]*v[3]
        end

        local function norm(v)
            return math.sqrt(dot(v,v))
        end

        local A = line[1]
        local B = line[2]
        local AB = vector_sub(B,A)
        local AP = vector_sub(p,A)

        local cross_vec = cross(AB, AP)
        local dist = norm(cross_vec) / norm(AB)

        -- Also need sign: find projection of AP onto AB perpendicular to AB
        -- sign = dot(cross(AB, AP), some reference vector). 
        -- Here we pick a consistent reference: AB cross with vector perpendicular to AB and in plane of triangle
        -- But simpler: pick sign by dot product with cross(AB, AP) and cross(AB, normal)

        -- For simplicity here, let's get the sign by dot product of vector from point projected to line

        -- We'll just use a rough approach: calculate vector perpendicular to AB in triangle plane
        -- Triangle normal
        local normal = cross(
            vector_sub(triangle[2], triangle[1]),
            vector_sub(triangle[3], triangle[1])
        )
        -- Sign based on dot product of cross_vec and normal
        local sign_val = dot(cross_vec, normal)
        if sign_val >= 0 then
            return dist
        else
            return -dist
        end
    end

    -- Compute distances of each vertex to the line
    local d = {}
    for i=1,3 do
        d[i] = point_on_side(triangle[i], line)
    end

    -- Classify vertices by sign
    local positive = {}
    local negative = {}
    for i=1,3 do
        if d[i] >= 0 then
            table.insert(positive, i)
        else
            table.insert(negative, i)
        end
    end

    -- If all on one side, return original triangle
    if #positive == 0 or #negative == 0 then
        return {triangle}
    end

    -- Helper to interpolate between two points by ratio t
    local function interp(p1, p2, t)
        return {
            p1[1] + t*(p2[1] - p1[1]),
            p1[2] + t*(p2[2] - p1[2]),
            p1[3] + t*(p2[3] - p1[3]),
        }
    end

    -- Find intersection points on edges crossing the line (zero crossing of distance)
    local function intersect(i1, i2)
        local p1, p2 = triangle[i1], triangle[i2]
        local dist1, dist2 = d[i1], d[i2]
        local t = dist1 / (dist1 - dist2)
        return interp(p1, p2, t)
    end

    local new_triangles = {}

    if #positive == 2 and #negative == 1 then
        -- Two positive, one negative
        -- Split into two triangles
        local i_neg = negative[1]
        local i_pos1 = positive[1]
        local i_pos2 = positive[2]

        local p_int1 = intersect(i_neg, i_pos1)
        local p_int2 = intersect(i_neg, i_pos2)

        -- Triangle 1: positive1, positive2, p_int1
        table.insert(new_triangles, {triangle[i_pos1], triangle[i_pos2], p_int1})
        -- Triangle 2: positive2, p_int1, p_int2
        table.insert(new_triangles, {triangle[i_pos2], p_int1, p_int2})

    elseif #negative == 2 and #positive == 1 then
        -- Two negative, one positive
        -- Split into one smaller triangle
        local i_pos = positive[1]
        local i_neg1 = negative[1]
        local i_neg2 = negative[2]

        local p_int1 = intersect(i_pos, i_neg1)
        local p_int2 = intersect(i_pos, i_neg2)

        -- Triangle: positive, p_int1, p_int2
        table.insert(new_triangles, {triangle[i_pos], p_int1, p_int2})
    else
        -- Should not happen for triangles but just in case
        return {triangle}
    end

    return new_triangles
end



return mm