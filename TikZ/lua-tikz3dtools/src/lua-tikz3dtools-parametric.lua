
--- indiscernable distance
local eps = 0.0000001

--- the dot product
--- @param u table<table<number>> a vector
--- @param v table<table<number>> another vector
--- @return number the dot product
local function dot_product(u, v)
    local a, b = u[1], v[1]
    return a[1]*b[1] + a[2]*b[2] + a[3]*b[3]
end

--- scalar multiplication
--- @param a number the scalar coefficient
--- @param v table<table<number>> the vector
--- @return table<table<number>> the scaled vector
local function scalar_multiplication(a, v)
    local tmp = v[1]
    return { {a*tmp[1], a*tmp[2], a*tmp[3], 1} }
end

--- normalizes a vector
--- @param v table<table<number>> the vector
--- @return table<table<number>> the vectors normalization
local function normalize(v)
    local u = v[1]
    local len = math.sqrt(u[1]^2 + u[2]^2 + u[3]^2)
    return { {u[1]/len, u[2]/len, u[3]/len, 1} }
end

--- sign function
--- @param number number a number
--- @return string the sign|zero
local function sign(number)
    if number >= -eps then return "positive" end
    return "negative"
end

--- distance between two points
--- @param P1 table<table<number>> a point
--- @param P2 table<table<number>> another point
--- @return number their distance
local function distance(P1, P2)
    local A = P1[1]
    local B = P2[1]
    return math.sqrt(
        (A[1]-B[1])^2 +
        (A[2]-B[2])^2 +
        (A[3]-B[3])^2
    )
end

--- vector subtraction
--- @param u table<table<number>> the first vector
--- @param v table<table<number>> the second vector
--- @return table<table<number>> their difference
local function vector_subtraction(u, v)
    local U = u[1]
    local V = v[1]
    return { {U[1]-V[1], U[2]-V[2], U[3]-V[3], 1} }
end

--- test for indistinguishable points
--- @param P1 table<table<number>> a point
--- @param P2 table<table<number>> another point
--- @return bool whether they intersect
local function point_point_intersecting(P1, P2)
    if distance(P1, P2) < eps then 
        return true 
    else 
        return false 
    end
end


-- Correct column-major Gauss-Jordan solver (drop-in replacement)
-- M is an array of columns; each column is an array of n rows.
-- Last column is RHS. Returns:
--   {solution = {..}, freevars = {..}}  on success
--   nil on inconsistency
--- @param M table<table<number>> an augmented matrix
--- @return table<table<number>> the solution set and free variables
local function gauss_jordan(M)

    -- basic validation
    local m = #M        -- number of columns (vars + RHS)
    if m == 0 then return {} end
    local n = #M[1]     -- number of rows (equations)
    local vars = m - 1
    if vars < 1 then return nil end
    for c = 1, m do
        if #M[c] ~= n then return nil end
    end

    -- Work on a local copy
    local cols = {}
    for c = 1, m do
        cols[c] = {}
        for r = 1, n do cols[c][r] = M[c][r] end
    end

    local rank = 0
    local row = 1
    local pivot_cols = {}  -- track pivot columns

    -- Gauss–Jordan elimination
    for col = 1, vars do
        -- find pivot row in column col, rows row..n
        local pivot_row = nil
        local maxval = eps
        for r = row, n do
            local v = math.abs(cols[col][r])
            if v > maxval then
                maxval = v
                pivot_row = r
            end
        end

        if pivot_row then
            -- swap pivot_row with current row
            if pivot_row ~= row then
                for c = 1, m do
                    cols[c][row], cols[c][pivot_row] = cols[c][pivot_row], cols[c][row]
                end
            end

            -- normalize pivot row
            local pivot = cols[col][row]
            for c = 1, m do
                cols[c][row] = cols[c][row] / pivot
            end

            -- eliminate column in other rows
            for r = 1, n do
                if r ~= row then
                    local factor = cols[col][r]
                    if math.abs(factor) > eps then
                        for c = 1, m do
                            cols[c][r] = cols[c][r] - factor * cols[c][row]
                        end
                        cols[col][r] = 0
                    end
                end
            end

            pivot_cols[#pivot_cols+1] = col
            rank = rank + 1
            row = row + 1
            if row > n then break end
        end
    end

    -- check for inconsistency: [0 0 ... | b] with b≠0
    for r = rank+1, n do
        local all_zero = true
        for c = 1, vars do
            if math.abs(cols[c][r]) > eps then
                all_zero = false
                break
            end
        end
        if all_zero and math.abs(cols[m][r]) > eps then
            return nil -- inconsistent
        end
    end

    -- Identify free variables
    local freevars = {}
    local pivotset = {}
    for _,c in ipairs(pivot_cols) do pivotset[c] = true end
    for c = 1, vars do
        if not pivotset[c] then
            freevars[#freevars+1] = c
        end
    end

    -- Extract one particular solution
    local sol = {}
    for i = 1, vars do sol[i] = 0 end
    for k,pcol in ipairs(pivot_cols) do
        sol[pcol] = cols[m][k]  -- solution from reduced form
    end

    return {solution = sol, freevars = freevars}
end

--- The orthogonal vector projection.
--- @param u table<table<number>> the vector being projected onto
--- @param v table<table<number>> the vector being projected
--- @return table<table<number>> the resulting projection
local function orthogonal_vector_projection(u, v)
    return scalar_multiplication(
        dot_product(v, u) / dot_product(u, u),
        u
    )
end

--- vector addition
--- @param u table<table<number>> the first vector
--- @param v table<table<number>> the second vector
--- @return table<table<number>> their sum
local function vector_addition(u, v)
    local U = u[1]
    local V = v[1]
    return { {U[1]+V[1], U[2]+V[2], U[3]+V[3], 1} }
end

--- determined whether a point and a line segment intersect
--- @param P table<table<number>> the point
--- @param L table<table<number>> the line segment
--- @return bool whether the point and line intersect
local function point_line_segment_intersecting(P, L)
    local LO = {L[1]}
    local LU = vector_subtraction({L[2]}, {L[1]})
    local LOP = vector_subtraction(P, LO)
    -- Check orthogonal projection distance
    local orth = orthogonal_vector_projection(LU, LOP)
    local real_orth = vector_addition(LO, orth)
    if distance(real_orth, P) >= eps then 
        return false 
    end
    local rhs = vector_subtraction(real_orth, LO)
    -- LO + (t) * LU = orth
    -- (t) * LU = orth - LO
    local augmented_matrix = {
        {LU[1][1], LU[1][2], LU[1][3]}
        ,{rhs[1][1], rhs[1][2], rhs[1][3]}
    }
    local sol = gauss_jordan(augmented_matrix)
    local t = sol.solution[1]
    return 0-eps<=t and t<=1+eps
end

--- the cross product
--- @param u table<table<number>> the first vector
--- @param v table<table<number>> the second vector
--- @return table<table<number>> their cross product
local function cross_product(u,v)
    local x = u[1][2]*v[1][3]-u[1][3]*v[1][2]
    local y = u[1][3]*v[1][1]-u[1][1]*v[1][3]
    local z = u[1][1]*v[1][2]-u[1][2]*v[1][1]
    return { {x, y, z, 1} }
end

--- Projects a point onto a plane (in a given affine basis)
--- @param P table<table<number>> the point
--- @param T table<table<number>> the AFFINE basis of the plane NOT ITS TRIANGLE
--- @return table<table<number>> the literal intersection and not the coordinates
local function orthogonal_projection_onto_plane(P, T)
    local TO = {T[1]}
    local TU = {T[2]}
    local TV = {T[3]}
    local TW = cross_product(TU, TV)
    local TOP = vector_subtraction(P, TO)
    local proj_TW_TOP = orthogonal_vector_projection(TW, TOP)
    return vector_subtraction(P, proj_TW_TOP)
end

--- determines if two parallel vectors are parallel or antiparallel
--- @param V1 table<table<number>> the first collinear vector
--- @param V2 table<table<number>> the second collinear vector
--- @return bool whether they are parallel or antiparalled
local function vector_sign_equality(V1, V2)
    return (
        sign(V1[1][1]) == sign(V2[1][1]) and
        sign(V1[1][2]) == sign(V2[1][2]) and
        sign(V1[1][3]) == sign(V2[1][3])
    )
end

--- determines whether a point that is known to be in the triangle's plane intersects it
--- @param P table<table<number>> the point which is known to be coplannar with the triangle
--- @param T table<table<number>> the triangle
--- @return bool whether they intersect
local function point_in_triangle(P, T)
    local T1 = vector_subtraction({T[2]}, {T[1]})
    local T2 = vector_subtraction({T[3]}, {T[2]})
    local T3 = vector_subtraction({T[1]}, {T[3]})
    local P1 = vector_subtraction(P, {T[1]})
    local P2 = vector_subtraction(P, {T[2]})
    local P3 = vector_subtraction(P, {T[3]})
    local C1 = cross_product(T1, P1)
    local C2 = cross_product(T2, P2)
    local C3 = cross_product(T3, P3)
    return (
        vector_sign_equality(C1, C2) == true and 
        vector_sign_equality(C2, C3) == true 
    )
end

--- detects whether a point and a triangle intersect
--- @param P table<table<number>> the point
--- @param T table<table<number>> the triangle
--- @return bool whether they intersect
local function point_triangle_intersecting(P, T)
    local TO = {T[1]}
    local TU = vector_subtraction({T[2]}, TO)
    local TV = vector_subtraction({T[3]}, TO)
    local affine_basis = {TO[1], TU[1], TV[1]}
    local S = orthogonal_projection_onto_plane(P, affine_basis)
    return distance(S, P) < eps and point_in_triangle(P, T)
end

--- return coordinates and free variables for line-line intersection
--- @param L1 table<table<number>> affine basis of a line
--- @param L1 table<table<number>> another 1D affine basis
--- @return table<table<number>> the solution and free variables
local function line_line_intersection(L1, L2)
    local L1O = {L1[1]}
    local L1U = {L1[2]}
    local L2O = {L2[1]}
    local L2U = {L2[2]}
    -- L1O + (t) * L1U = L2O + (s) * L2U
    -- (t) * L1U - (s) * L2U = L1O - L2O
    local rhs = vector_subtraction(L2O, L1O)
    local augmented_matrix = {
        {L1U[1][1], L1U[1][2], L1U[1][3]},
        {-L2U[1][1], -L2U[1][2], -L2U[1][3]},
        {rhs[1][1], rhs[1][2], rhs[1][3]}
    }
    return gauss_jordan(augmented_matrix)
end

--- determines the solution coefficients and solution set of two line segments, or produces nil
--- @param L1 table<table<number>> the first line segment
--- @param L2 table<table<number>> the second line segment
--- @return table<table<table<number>>,table<table<number>>>|nil the solution coefficients and solution set
local function line_segment_line_segment_intersection(L1, L2)
    local L1O = {L1[1]}
    local L1U = vector_subtraction({L1[2]}, L1O)
    local L1A = {L1O[1], L1U[1]}
    local L2O = {L2[1]}
    local L2U = vector_subtraction({L2[2]}, L2O)
    local L2A = {L2O[1], L2U[1]}
    local coeffs = line_line_intersection(L1A, L2A)
    if coeffs == nil then return nil end
    if #coeffs.solution == 0 then return nil end
    local t, s = coeffs.solution[1], coeffs.solution[2]
    if 0-eps <= t and t <= 1+eps and 0-eps <= s and s <= 1+eps then
        return {
            coefficients = coeffs,
            intersection = vector_addition(
                L1O,
                scalar_multiplication(t, L1U)
            )
        }
    end
    return nil
end

--- length of a vector
--- @param u table<table<number>> the vector to be measured
--- @return number the vectors length
local function length(u)
    local result = math.sqrt((u[1][1])^2 + (u[1][2])^2 + (u[1][3])^2)
    return result
end

--- obtains the coordinates and free variables of the intersection 
--- between a line and a plane, each defined by their affine bases.
--- @param L table<table<number>> an affine basis of a line
--- @param T table<table<number>> an affine basis of a plane
--- @return table<table<number>> the solution and free variables
local function line_plane_intersection(L, T)
    local LO = {L[1]}
    local LU = {L[2]}
    local TO = {T[1]}
    local TU = {T[2]}
    local TV = {T[3]}
    --- LO + (t) * LU = TO + (s) * TU + (w) * TV
    -- (t) * LU - (s) * TU - (w) * TV = TO - LO
    local rhs = vector_subtraction(TO, LO)


    local normal = cross_product(TU, TV)
    local normal_length = length(normal)
    if normal_length < eps then
        -- plane basis is degenerate (area ~ 0)
        return nil
    end
    -- Check if line direction is perpendicular to normal (i.e. lies in plane)
    dot_product(LU, normal)
    if math.abs(dot_product(LU, normal)) < eps then
        -- line direction is parallel to the plane. Now check if the line lies in plane:
        if math.abs(dot_product(rhs, normal)) < eps then
            -- the line lies in the plane (coplanar)
            return { solution = {}, freevars = {1}, coplanar = true }
        else
            -- line is parallel but not in plane -> no intersection
            return nil
        end
    end


    local augmented_matrix = {
        {LU[1][1], LU[1][2], LU[1][3]},
        {-TU[1][1], -TU[1][2], -TU[1][3]},
        {-TV[1][1], -TV[1][2], -TV[1][3]},
        {rhs[1][1], rhs[1][2], rhs[1][3]}
    }
    local sol = gauss_jordan(augmented_matrix)
    if not sol then
        print("No solution: line-plane system inconsistent")
        return nil
    end
    if #sol.freevars > 0 then
        print("Line lies in the plane (coplanar case). Free vars:", #sol.freevars)
    end
    return sol
end

--- determines the intersection coefficients and intersection point of a line segment and triangle, if it exists, or returns nil
--- @param L table<table<number>> line segment defined by endpoints
--- @param T table<table<number>> triangle defined by vertices
--- @return table<table<table<number>>,table<table<number>>>|nil the solution coefficients and literal R3 intersection point
local function line_segment_triangle_intersection(L, T)
    local eps = 0.0000001
    local LO = {L[1]}
    local LU = vector_subtraction({L[2]}, LO)
    local LA = {LO[1], LU[1]}
    local TO = {T[1]}
    local TU = vector_subtraction({T[2]}, TO)
    local TV = vector_subtraction({T[3]}, TO)
    local TA = {TO[1], TU[1], TV[1]}
    local coeffs = line_plane_intersection(LA, TA)
    if coeffs == nil then return nil end 
    if #coeffs.solution == 0 then return nil end 
    local t = coeffs.solution[1]
    if 0-eps<=t and t<=1+eps then
        if t>1 then t = 1 elseif t<0 then t = 0 end
        local I = vector_addition(
            LO,
            scalar_multiplication(t, LU)
        )
        if point_in_triangle(I, T) then 
            return {
                solution = coeffs,
                intersection = I
            }
        end
    end
    return nil
end

--- produces exactly zero, or exactly two intersection points between two triangles
--- @param T1 table<table<number>> a triangle defined by its vertices
--- @param T2 table<table<number>> another triangle defined by its vertices
--- @return table<table<number>> a matrix of exactly zero or exactly two points nothing else
local function triangle_triangle_intersections(T1, T2)
    local edges1 = { {T1[1], T1[2]}, {T1[2], T1[3]}, {T1[3], T1[1]} }
    local edges2 = { {T2[1], T2[2]}, {T2[2], T2[3]}, {T2[3], T2[1]} }

    local points = {}

    --- appends a point to a list if it is unique
    --- @param P table<table<number>> a point
    local function add_unique(P)
        if not P then return nil end
        for _, Q in ipairs(points) do
            if distance(P, Q) < eps then return nil end
        end
        table.insert(points, P)
    end

    -- Check all edge pairs
    for _, E1 in ipairs(edges1) do
        local intersect = line_segment_triangle_intersection(E1, T2)
        if intersect ~= nil then
            add_unique(intersect.intersection)
        end
    end
    for _, E2 in ipairs(edges2) do
        local intersect = line_segment_triangle_intersection(E2, T1)
        if intersect ~= nil then
            add_unique(intersect.intersection)
        end
    end

    if #points == 0 then return nil end
    if #points == 1 then return nil end
    if #points ~= 2 then
        return nil 
        --assert(false, ("two triangles intersected at %f points"):format(#points)) 
    end
    return points
end

--- returns a table of line segments - the partition of L into two - if L itnersects a point, else returns nil
--- @param P table<table<number>> the point
--- @param L table<table<number>> the line segment
--- @return table<table<table<number>>,table<table<number>>>|nil the intersection points if they exist
local function point_line_segment_partition(P, L)
    if point_line_segment_intersecting(P, L) then 
        return {
            point1 = {L[1], P[1]}, 
            point2 = {L[2], P[1]}
        }
    end 
    return nil
end

--- if two line segments intersect, returns the pieces of the first 
--- one, after being partitioned by the intersection with the other
--- @param L1 table<table<number>> the first line segment
--- @param L2 table<table<number>> the second line segment
--- @return table<table<table<number>>,table<table<number>>> the fragmented pieces of the first segment
local function line_segment_line_segment_partition(L1, L2)
    local eps = 0.0000001
    local intersect = line_segment_line_segment_intersection(L1, L2)
    if intersect == nil then return nil end
    local I = intersect.intersection
    if distance(I, L1) < eps or distance(I, L2) < eps then return nil end
    return {
        line_segment1 = {L1[1], I[1]},
        line_segment2 = {L1[2], I[1]}
    }
end

--- partitions a line segment by its intersection with a triangle, or returns nil
--- @param L table<table<number>> the line segment
--- @param T table<table<number>> the triangle
--- @return table<table<table<number>>,table<table<number>>>|nil the partitioned line segment or nil
local function line_segment_triangle_clip(L, T)
    local intersect = line_segment_triangle_intersection(L, T)
    if intersect == nil then return nil end
    local I = intersect.intersection
    return {
        line_segment1 = {L[1], I[1]},
        line_segment2 = {L[2], I[1]}
    }
end

--- ChatGPT written centroid sorting function, for the purpose of convex polygon ordering
--- @param points table<table<number>> the not necessarily convex matrix of polygon points
--- @return table<table<number>> the definitively convex matrix of polygon points
local function centroid_sort(points)
    local num = #points
    assert(num >= 3, "Need at least 3 points to sort by centroid.")

    -- Compute centroid
    local sum = { {0, 0, 0, 1} }
    for i = 1, num do
        sum = vector_addition(sum, {points[i]})
    end
    local centroid = scalar_multiplication(1/num, sum)

    -- Build local basis for projection
    local v1 = vector_subtraction({points[2]}, {points[1]})
    local v2 = vector_subtraction({points[3]}, {points[1]})
    local normal = cross_product(v1, v2)

    -- Pick axes in the plane
    local x_axis = v1
    local y_axis = cross_product(normal, x_axis)

    x_axis = normalize(x_axis)
    y_axis = normalize(y_axis)

    -- Compute angle of each point relative to centroid
    local angles = {}
    for i, P in ipairs(points) do
        local rel = vector_subtraction({P}, centroid)[1]
        local x = rel[1]*x_axis[1][1] + rel[2]*x_axis[1][2] + rel[3]*x_axis[1][3]
        local y = rel[1]*y_axis[1][1] + rel[2]*y_axis[1][2] + rel[3]*y_axis[1][3]
        local theta = math.atan2(y, x)
        table.insert(angles, {point = P, angle = theta})
    end

    -- Sort by angle
    table.sort(angles, function(a, b) return a.angle < b.angle end)

    -- Extract sorted points
    local sorted = {}
    for _, entry in ipairs(angles) do
        table.insert(sorted, entry.point)
    end

    return sorted
end

--- returns the partitio of the first triangle into three subtriangles, 
--- if it intersects the second, otherwise produces nil
--- @param T1 table<table<number>> the first triangle
--- @param T2 table<table<number>> the second triangle
--- @return table<table<table<number>>,table<table<number>>,table<table<number>>> table of sub triangles
local function triangle_triangle_partition(T1, T2)
    local I = triangle_triangle_intersections(T1, T2)
    if I == nil then return nil end
    if #I == 0 then return nil end
    if #I == 1 then return nil end
    if #I ~= 2 then  assert(false, ("I is not 2, it is instead: %f"):format(#I)) end
    
    local IO = I[1]
    local IU = vector_subtraction(I[2], IO)
    local I_basis = {IO[1], IU[1]}
    local T1A = {T1[1], T1[2]}
    local T1AU = vector_subtraction({T1A[2]}, {T1A[1]})
    local T1A_basis = {T1A[1], T1AU[1]}
    local T1B = {T1[2], T1[3]}
    local T1BU = vector_subtraction({T1B[2]}, {T1B[1]})
    local T1B_basis = {T1B[1], T1BU[1]}
    local T1C = {T1[3], T1[1]}
    local T1CU = vector_subtraction({T1C[2]}, {T1C[1]})
    local T1C_basis = {T1C[1], T1CU[1]}
    local T2A = {T2[1], T2[2]}
    local T2AU = vector_subtraction({T2A[2]}, {T2A[1]})
    local T2A_basis = {T2A[1], T2AU[1]}
    local T2B = {T2[2], T2[3]}
    local T2BU = vector_subtraction({T2B[2]}, {T2B[1]})
    local T2B_basis = {T2B[1], T2BU[1]}
    local T2C = {T2[3], T2[1]}
    local T2CU = vector_subtraction({T2C[2]}, {T2C[1]})
    local T2C_basis = {T2C[1], T2CU[1]}

    local points = {}
    local non_intersecting = nil

    local int1 = line_line_intersection(I_basis, T1A_basis)
    if int1 == nil then 
        int1 = {solution = {}}
    end
    if #int1.solution ~= 0 then 
        local t = int1.solution[1]
        local intersect = vector_addition(
            IO,
            scalar_multiplication(t, IU)
        )
        if point_line_segment_intersecting(intersect, T1A) then
            table.insert(points, intersect)
        else 
            non_intersecting = "T1A" 
        end
    else 
        non_intersecting = "T1A"
    end

    local int2 = line_line_intersection(I_basis, T1B_basis)
    if int2 == nil then 
        int2 = {solution = {}}
    end
    if #int2.solution ~= 0 then 
        local t = int2.solution[1]
        local intersect = vector_addition(
            IO,
            scalar_multiplication(t, IU)
        )
        if point_line_segment_intersecting(intersect, T1B) then
            table.insert(points, intersect)
        else 
            non_intersecting = "T1B" 
        end
    else 
        non_intersecting = "T1B"
    end

    local int3 = line_line_intersection(I_basis, T1C_basis)
    if int3 == nil then 
        int3 = {solution = {}}
    end
    if #int3.solution ~= 0 then 
        local t = int3.solution[1]
        local intersect = vector_addition(
            IO,
            scalar_multiplication(t, IU)
        )
        if point_line_segment_intersecting(intersect, T1C) then
            table.insert(points, intersect)
        else 
            non_intersecting = "T1C" 
        end
    else 
        non_intersecting = "T1C"
    end

    if #points == 3 then return nil end 
    if #points == 1 then return nil end 
    if #points ~= 2 then
        print("Partition failure: got", #points, "points")
        print("Triangle 1:", T1)
        print("Triangle 2:", T2)
        print("Non-intersecting edge:", non_intersecting)
        for i, p in ipairs(points) do
            print("Point", i, p[1][1], p[1][2], p[1][3])
        end
        return nil
        --assert(false, "triangle_triangle_partition doesn't have exactly two points")
    end
    local quad = {}
    local tri1
    local A, B = points[1], points[2]
    table.insert(quad, A[1])
    table.insert(quad, B[1])
    if non_intersecting == "T1A" then 
        table.insert(quad, T1A[1])
        table.insert(quad, T1A[2])
        tri1 = {A[1], B[1], T1B[2]}
    elseif non_intersecting == "T1B" then 
        table.insert(quad, T1B[1])
        table.insert(quad, T1B[2])
        tri1 = {A[1], B[1], T1C[2]}
    elseif non_intersecting == "T1C" then
        table.insert(quad, T1C[1])
        table.insert(quad, T1C[2])
        tri1 = {A[1], B[1], T1A[2]}
    end
    quad = centroid_sort(quad)
    return {
        tri1 = tri1,
        tri2 = {quad[1], quad[2], quad[3]},
        tri3 = {quad[3], quad[4], quad[1]}
    }
end
























-- https://tex.stackexchange.com/a/747040
--- Creates a TeX command that evaluates a Lua function
---
--- @param name string The name of the `\csname` to define
--- @param func function
--- @param args table<string> The TeX types of the function arguments
--- @param protected boolean|nil Define the command as `\protected`
--- @return nil
local function register_tex_cmd(name, func, args, protected)
    -- The extended version of this function uses `N` and `w` where appropriate,
    -- but only using `n` is good enough for exposition purposes.
    name = "__lua_tikztdtools_" .. name .. ":" .. ("n"):rep(#args)

    -- Push the appropriate scanner functions onto the scanning stack.
    local scanners = {}
    for _, arg in ipairs(args) do
        scanners[#scanners+1] = token['scan_' .. arg]
    end

    -- An intermediate function that properly "scans" for its arguments
    -- in the TeX side.
    local scanning_func = function()
        local values = {}
        for _, scanner in ipairs(scanners) do
            values[#values+1] = scanner()
        end

        func(table.unpack(values))
    end

    local index = luatexbase.new_luafunction(name)
    lua.get_functions_table()[index] = scanning_func

    if protected then
        token.set_lua(name, index, "protected")
    else
        token.set_lua(name, index)
    end
end



local segments = {}

local mm = require"lua-tikz3dtools-matrix"
local lua_tikz3dtools_parametric = {}
lua_tikz3dtools_parametric.math = {}
for k, v in pairs(_G) do lua_tikz3dtools_parametric.math[k] = v end
for k, v in pairs(mm) do lua_tikz3dtools_parametric.math[k] = v end
for k, v in pairs(math) do lua_tikz3dtools_parametric.math[k] = v end

local function single_string_expression(str)
    return load(("return %s"):format(str), "expression", "t", lua_tikz3dtools_parametric.math)()
end

local function single_string_function(str)
    return load(("return function(u) return %s end"):format(str), "expression", "t", lua_tikz3dtools_parametric.math)()
end

local function double_string_function(str)
    return load(("return function(u,v) return %s end"):format(str), "expression", "t", lua_tikz3dtools_parametric.math)()
end

local function triple_string_function(str)
    return load(("return function(u,v,w) return %s end"):format(str), "expression", "t", lua_tikz3dtools_parametric.math)()
end


local function append_point(hash)
    local x              = hash.x
    local y              = hash.y
    local z              = hash.z
    local filloptions   = hash.filloptions
    local transformation = hash.transformation

    x = single_string_expression(x)
    y = single_string_expression(y)
    z = single_string_expression(z)
    transformation = single_string_expression(transformation)

    local A = { { x, y, z, 1 } }
    local the_segment = mm.matrix_multiply(A, transformation)
    table.insert(
        segments, 
        { 
            segment = the_segment, 
            filloptions = filloptions, 
            type = "point" 
        }
    )
end
register_tex_cmd(
    "appendpoint",
    function()
        append_point{
            x              = token.get_macro("luatikztdtools@p@p@x"),
            y              = token.get_macro("luatikztdtools@p@p@y"),
            z              = token.get_macro("luatikztdtools@p@p@z"),
            filloptions    = token.get_macro("luatikztdtools@p@p@filloptions"),
            transformation = token.get_macro("luatikztdtools@p@p@transformation")
        } 
    end,
    { }
)

local function append_label(hash)
    local x              = hash.x
    local y              = hash.y
    local z              = hash.z
    local name   = hash.name
    local transformation = hash.transformation

    x = single_string_expression(x)
    y = single_string_expression(y)
    z = single_string_expression(z)
    transformation = single_string_expression(transformation)

    local A = { { x, y, z, 1 } }
    local the_segment = mm.matrix_multiply(A, transformation)
    table.insert(
        segments, 
        { 
            segment = the_segment, 
            type = "point",
            name = name
        }
    )
end
register_tex_cmd(
    "appendlabel",
    function()
        append_label{
            x              = token.get_macro("luatikztdtools@p@l@x"),
            y              = token.get_macro("luatikztdtools@p@l@y"),
            z              = token.get_macro("luatikztdtools@p@l@z"),
            name           = token.get_macro("luatikztdtools@p@l@name"),
            transformation = token.get_macro("luatikztdtools@p@l@transformation")
        } 
    end,
    { }
)


local function append_surface(hash)
    local ustart         = hash.ustart
    local ustop          = hash.ustop
    local usamples       = hash.usamples
    local vstart         = hash.vstart
    local vstop          = hash.vstop
    local vsamples       = hash.vsamples
    local x              = hash.x
    local y              = hash.y
    local z              = hash.z
    local drawoptions    = hash.drawoptions
    local filloptions    = hash.filloptions
    local transformation = hash.transformation

    x = double_string_function(x)
    y = double_string_function(y)
    z = double_string_function(z)

    ustart = single_string_expression(ustart)
    ustop = single_string_expression(ustop)
    usamples = single_string_expression(usamples)
    vstart = single_string_expression(vstart)
    vstop = single_string_expression(vstop)
    vsamples = single_string_expression(vsamples)
    transformation = single_string_expression(transformation)

    local ustep = (ustop - ustart) / (usamples - 1)
    local vstep = (vstop - vstart) / (vsamples - 1)

    local function parametric_surface(u, v)
        return { x(u,v), y(u,v), z(u,v), 1 }
    end

    local function distance(P1, P2)
        return math.sqrt(
            (P1[1]-P2[1])^2 +
            (P1[2]-P2[2])^2 +
            (P1[3]-P2[3])^2
        )
    end
    local eps = 0.0000001

    for i = 0, usamples - 2 do
        local u = ustart + i * ustep
        for j = 0, vsamples - 2 do
            local v = vstart + j * vstep
            local A = parametric_surface(u, v)
            local B = parametric_surface(u + ustep, v)
            local C = parametric_surface(u, v + vstep)
            local D = parametric_surface(u + ustep, v + vstep)
            local the_segment1 = mm.matrix_multiply({ A, B, D },transformation)
            local the_segment2 = mm.matrix_multiply({ A, C, D },transformation)
            if not (
                distance(A, B) < eps or
                distance(B, D) < eps or
                distance(A, D) < eps
            ) then
                table.insert(
                    segments, 
                    { 
                        segment      = the_segment1, 
                        filloptions = filloptions, 
                        type         = "triangle" 
                    }
                )
            end
            if not (
                distance(A, C) < eps or
                distance(C, D) < eps or
                distance(A, D) < eps
            ) then
                table.insert(
                    segments, 
                    { 
                        segment      = the_segment2, 
                        filloptions = filloptions, 
                        type         = "triangle" 
                    }
                )
            end
        end
    end
end
register_tex_cmd(
    "appendsurface", 
    function()
        append_surface{
            ustart         = token.get_macro("luatikztdtools@p@s@ustart"),
            ustop          = token.get_macro("luatikztdtools@p@s@ustop"),
            usamples       = token.get_macro("luatikztdtools@p@s@usamples"),
            vstart         = token.get_macro("luatikztdtools@p@s@vstart"),
            vstop          = token.get_macro("luatikztdtools@p@s@vstop"),
            vsamples       = token.get_macro("luatikztdtools@p@s@vsamples"),
            x              = token.get_macro("luatikztdtools@p@s@x"),
            y              = token.get_macro("luatikztdtools@p@s@y"),
            z              = token.get_macro("luatikztdtools@p@s@z"),
            transformation = token.get_macro("luatikztdtools@p@s@transformation"),
            filloptions    = token.get_macro("luatikztdtools@p@s@filloptions"),
        } 
    end,
    { }
)

local function append_curve(hash)
    local ustart         = hash.ustart
    local ustop          = hash.ustop
    local usamples       = hash.usamples
    local x              = hash.x
    local y              = hash.y
    local z              = hash.z
    local transformation = hash.transformation
    local drawoptions    = hash.drawoptions 
    local arrowtip       = single_string_expression(hash.arrowtip)
    local arrowtail      = single_string_expression(hash.arrowtail)
    local arrowoptions   = hash.arrowoptions

    ustart = single_string_expression(ustart)
    ustop = single_string_expression(ustop)
    usamples = single_string_expression(usamples)
    x = single_string_function(x)
    y = single_string_function(y)
    z = single_string_function(z)
    transformation = single_string_expression(transformation)
    drawoptions = drawoptions

    local ustep = (ustop - ustart) / (usamples - 1)

    local function parametric_curve(u)
        return { { x(u), y(u), z(u), 1 } }
    end

    for i = 0, usamples - 2 do
        local u = ustart + i * ustep
        local A = parametric_curve(u)
        local B = parametric_curve(u+ustep)
        local thesegment = mm.matrix_multiply({ A[1], B[1] }, transformation)
        table.insert(
            segments, 
            { 
                segment = thesegment, 
                drawoptions = drawoptions, 
                type = "line segment" 
            }
        )            
        if i == 0 and arrowtail == true then
            -- append_surface{
                
            -- }
        elseif i == usamples - 2 and arrowtip == true then
            local P = parametric_curve(ustop)
            local NP = parametric_curve(ustop-ustep)
            NP = mm.matrix_subtract(P, NP)
            NP = mm.normalize(NP)
            local U = mm.cross_product(NP, mm.orthogonal_vector(NP))
            local V = mm.cross_product(NP, U)
            append_surface{
                ustart = 0
                ,ustop = 0.1
                ,usamples = 2
                ,vstart = 0
                ,vstop = 1
                ,vsamples = 4
                ,x = "u*cos(v*tau)"
                ,y = "u*sin(v*tau)"
                ,z = "-u"
                ,filloptions = arrowoptions
                ,transformation = ([[
                    matrix_multiply(
                        {
                            {%f,%f,%f,0}
                            ,{%f,%f,%f,0}
                            ,{%f,%f,%f,0}
                            ,{%f,%f,%f,1}
                        }
                        ,%s
                    )
                ]]):format(
                    U[1][1],U[1][2],U[1][3]
                    ,V[1][1],V[1][2],V[1][3]
                    ,NP[1][1],NP[1][2],NP[1][3]
                    ,P[1][1],P[1][2],P[1][3]
                    ,hash.transformation
                )
            }
        end
    end
end
register_tex_cmd(
    "appendcurve",
    function()
        append_curve{
            ustart         = token.get_macro("luatikztdtools@p@c@ustart"),
            ustop          = token.get_macro("luatikztdtools@p@c@ustop"),
            usamples       = token.get_macro("luatikztdtools@p@c@usamples"),
            x              = token.get_macro("luatikztdtools@p@c@x"),
            y              = token.get_macro("luatikztdtools@p@c@y"),
            z              = token.get_macro("luatikztdtools@p@c@z"),
            transformation = token.get_macro("luatikztdtools@p@c@transformation"),
            drawoptions    = token.get_macro("luatikztdtools@p@c@drawoptions"),
            arrowtip       = token.get_macro("luatikztdtools@p@c@arrowtip"),
            arrowtail      = token.get_macro("luatikztdtools@p@c@arrowtail"),
            arrowoptions   = token.get_macro("luatikztdtools@p@c@arrowtipoptions")
        } 
    end,
    { }
)









local function append_solid(hash)
    -- Evaluate bounds and samples
    local ustart   = single_string_expression(hash.ustart)
    local ustop    = single_string_expression(hash.ustop)
    local usamples = single_string_expression(hash.usamples)
    local vstart   = single_string_expression(hash.vstart)
    local vstop    = single_string_expression(hash.vstop)
    local vsamples = single_string_expression(hash.vsamples)
    local wstart   = single_string_expression(hash.wstart)
    local wstop    = single_string_expression(hash.wstop)
    local wsamples = single_string_expression(hash.wsamples)
    local filloptions    = hash.filloptions
    local transformation = single_string_expression(hash.transformation)

    -- Compile x,y,z as triple-string functions
    local x = triple_string_function(hash.x)
    local y = triple_string_function(hash.y)
    local z = triple_string_function(hash.z)

    -- Parametric solid function
    local function parametric_solid(u,v,w)
        return { x(u,v,w), y(u,v,w), z(u,v,w), 1 }
    end

    -- Steps for tessellation
    local ustep = (ustop - ustart)/(usamples-1)
    local vstep = (vstop - vstart)/(vsamples-1)
    local wstep = (wstop - wstart)/(wsamples-1)

    -- Helper to tessellate a single face
    local function tessellate_face(fixed_var, fixed_val, s1_start, s1_step, s1_count, s2_start, s2_step, s2_count)
        for i = 0, s1_count-2 do
            local s1a = s1_start + i*s1_step
            local s1b = s1_start + (i+1)*s1_step
            for j = 0, s2_count-2 do
                local s2a = s2_start + j*s2_step
                local s2b = s2_start + (j+1)*s2_step

                -- Compute 4 corners of the quad
                local A,B,C,D
                if fixed_var == "u" then
                    A = parametric_solid(fixed_val, s1a, s2a)
                    B = parametric_solid(fixed_val, s1b, s2a)
                    C = parametric_solid(fixed_val, s1a, s2b)
                    D = parametric_solid(fixed_val, s1b, s2b)
                elseif fixed_var == "v" then
                    A = parametric_solid(s1a, fixed_val, s2a)
                    B = parametric_solid(s1b, fixed_val, s2a)
                    C = parametric_solid(s1a, fixed_val, s2b)
                    D = parametric_solid(s1b, fixed_val, s2b)
                else -- fixed_var == "w"
                    A = parametric_solid(s1a, s2a, fixed_val)
                    B = parametric_solid(s1b, s2a, fixed_val)
                    C = parametric_solid(s1a, s2b, fixed_val)
                    D = parametric_solid(s1b, s2b, fixed_val)
                end

                -- Insert two triangles for the quad
                table.insert(segments, { segment = mm.matrix_multiply({A,B,D}, transformation), filloptions=filloptions, type="triangle" })
                table.insert(segments, { segment = mm.matrix_multiply({A,C,D}, transformation), filloptions=filloptions, type="triangle" })
            end
        end
    end

    -- Tessellate all 6 faces
    tessellate_face("w", wstart, ustart, ustep, usamples, vstart, vstep, vsamples) -- front
    tessellate_face("w", wstop,  ustart, ustep, usamples, vstart, vstep, vsamples) -- back
    tessellate_face("u", ustart, vstart, vstep, vsamples, wstart, wstep, wsamples) -- left
    tessellate_face("u", ustop,  vstart, vstep, vsamples, wstart, wstep, wsamples) -- right
    tessellate_face("v", vstart, ustart, ustep, usamples, wstart, wstep, wsamples) -- bottom
    tessellate_face("v", vstop,  ustart, ustep, usamples, wstart, wstep, wsamples) -- top
end


register_tex_cmd(
    "appendsolid", 
    function()
        append_solid{
            ustart         = token.get_macro("luatikztdtools@p@solid@ustart"),
            ustop          = token.get_macro("luatikztdtools@p@solid@ustop"),
            usamples       = token.get_macro("luatikztdtools@p@solid@usamples"),
            vstart         = token.get_macro("luatikztdtools@p@solid@vstart"),
            vstop          = token.get_macro("luatikztdtools@p@solid@vstop"),
            vsamples       = token.get_macro("luatikztdtools@p@solid@vsamples"),
            wstart         = token.get_macro("luatikztdtools@p@solid@wstart"),
            wstop          = token.get_macro("luatikztdtools@p@solid@wstop"),
            wsamples       = token.get_macro("luatikztdtools@p@solid@wsamples"),
            x              = token.get_macro("luatikztdtools@p@solid@x"),
            y              = token.get_macro("luatikztdtools@p@solid@y"),
            z              = token.get_macro("luatikztdtools@p@solid@z"),
            transformation = token.get_macro("luatikztdtools@p@solid@transformation"),
            filloptions    = token.get_macro("luatikztdtools@p@solid@filloptions")
        } 
    end,
    { }
)




-- ========================================================================
-- Canonical fragment signature + helpers
-- ========================================================================

local function canonicalize_segment(seg, eps)
  eps = eps or 1e-4
  local out = {}
  -- remove near-duplicates
  for _, P in ipairs(seg) do
    local x,y,z = P[1] or 0, P[2] or 0, P[3] or 0
    if #out == 0 then
      out[#out+1] = {x,y,z}
    else
      local q = out[#out]
      if math.abs(q[1]-x) > eps or math.abs(q[2]-y) > eps or math.abs(q[3]-z) > eps then
        out[#out+1] = {x,y,z}
      end
    end
  end
  -- collapse colinear (2D check only)
  local final = {}
  for i=1,#out do
    if i==1 or i==#out then
      final[#final+1] = out[i]
    else
      local a, b, c = out[i-1], out[i], out[i+1]
      local dx1,dy1 = b[1]-a[1], b[2]-a[2]
      local dx2,dy2 = c[1]-b[1], c[2]-b[2]
      if math.abs(dx1*dy2 - dy1*dx2) > eps then
        final[#final+1] = b
      end
    end
  end
  return final
end

-- ========================================================================
-- Canonical fragment signature (UID-based, non-geometric)
-- ========================================================================
-- Geometric signature (stable across partitions)
local function fragment_signature(f, eps)
  eps = eps or 1e-4
  local pts = {}
  if f.segment then
    local seg = canonicalize_segment(f.segment, eps)
    for _, P in ipairs(seg) do
      local x = math.floor((P[1] or 0)/eps + 0.5)
      local y = math.floor((P[2] or 0)/eps + 0.5)
      local z = math.floor((P[3] or 0)/eps + 0.5)
      pts[#pts+1] = string.format("%d,%d,%d", x, y, z)
    end
    table.sort(pts)
  end
  local t = f.type or "unknown"
  if t == "line" then t = "line segment" end
  return t .. "|" .. table.concat(pts, ";")
end


-- ========================================================================
-- Topological sort with partitioning and cycle handling
-- ========================================================================

local function topo_sort_with_cycles(items, cmp, max_depth)
  max_depth = max_depth or 2000
  local eps_local = 1e-4   -- less strict tolerance
  local DEBUG = false

  local global_seen = {}   -- local deduplication per call

  -- ---------------------------------------------------------------
  -- type checks
  -- ---------------------------------------------------------------
  local function is_line_segment(p) return p.type == "line segment" or p.type == "line" end
  local function is_triangle(p) return p.type == "triangle" end
  local function is_point(p) return p.type == "point" end

  local function get_bbox(p)
    local minX, maxX = math.huge, -math.huge
    local minY, maxY = math.huge, -math.huge
    for _, P in ipairs(p.segment or {}) do
      local x, y = P[1] or 0, P[2] or 0
      minX, maxX = math.min(minX, x), math.max(maxX, x)
      minY, maxY = math.min(minY, y), math.max(maxY, y)
    end
    return minX, maxX, minY, maxY
  end

  local function bboxes_overlap(b1, b2)
    local minX1, maxX1, minY1, maxY1 = table.unpack(b1)
    local minX2, maxX2, minY2, maxY2 = table.unpack(b2)
    return not (maxX1 < minX2 or maxX2 < minX1 or maxY1 < minY2 or maxY2 < minY1)
  end

  -- ---------------------------------------------------------------
  -- cloning / projection helpers
  -- ---------------------------------------------------------------
  local next_frag_id = 1
  local function clone_fragment(orig)
    local copy = {}
    for k,v in pairs(orig) do if k ~= "segment" then copy[k] = v end end
    copy.segment = {}
    for _, P in ipairs(orig.segment or {}) do
      copy.segment[#copy.segment+1] = {P[1], P[2], P[3], P[4]}
    end
    copy.__id = next_frag_id; next_frag_id = next_frag_id + 1
    return copy
  end

  local function convert_clone_segment_to_projected(clone)
    local out = {}
    for _, P in ipairs(clone.segment or {}) do
      local x, y, z, w = P[1] or 0, P[2] or 0, P[3] or 0, P[4]
      if w == nil or w == 0 then
        out[#out+1] = {x,y,z}
      else
        local rw = 1/w
        out[#out+1] = {x*rw, y*rw, z*rw}
      end
    end
    clone.segment = out
    return #out > 0
  end

  local function make_fragment_from_points(pts, orig)
    local typ = (#pts==1 and "point") or (#pts==2 and "line segment") or "triangle"
    if #pts > 3 then while #pts > 3 do table.remove(pts) end end
    local frag = {}
    for k,v in pairs(orig or {}) do frag[k] = v end
    frag.segment = {}
    for _, P in ipairs(pts) do frag.segment[#frag.segment+1] = {P[1],P[2],P[3]} end
    frag.type = typ
    frag.__id = next_frag_id; next_frag_id = next_frag_id + 1
    return frag
  end

  local function normalize_points(arr)
    local out = {}
    for _, P in ipairs(arr or {}) do
      if #P >= 3 then out[#out+1] = {P[1],P[2],P[3]} end
    end
    return out
  end

  local function fragments_from_partition_result(result, orig)
    local frags = {}
    if not result then return frags end
    for _, pts in pairs(result) do
      local eu = normalize_points(pts)
      if #eu > 0 then
        frags[#frags+1] = make_fragment_from_points(eu, orig)
      end
    end
    return frags
  end

  -- ---------------------------------------------------------------
  -- splice helper
  -- ---------------------------------------------------------------
  local function splice_replace_at(tbl, idx, frags)
    if DEBUG then
      texio.write_nl(("lua | splice_replace_at: replacing index %d with %d fragments"):format(idx,#frags))
    end
    table.remove(tbl, idx)
    for k=#frags,1,-1 do table.insert(tbl, idx, frags[k]) end
  end

  -- ---------------------------------------------------------------
  -- working copy
  -- ---------------------------------------------------------------
  local working = {}
  for i=1,#items do
    local c = clone_fragment(items[i])
    if convert_clone_segment_to_projected(c) then
      working[#working+1] = c
    end
  end

  -- ---------------------------------------------------------------
  -- partition loop
  -- ---------------------------------------------------------------
  local iter, changed = 0, true
  while changed and iter < max_depth do
    iter = iter+1
    changed = false
    local attempted = {}   -- reset each outer iteration

    local i=1
    while i <= #working do
      local j=i+1
      while j <= #working do
        local A,B = working[i], working[j]
        if not bboxes_overlap({get_bbox(A)}, {get_bbox(B)}) then
          j=j+1
        else
          local partA, partB, action
          if is_triangle(A) and is_triangle(B) then
            action="tt_A"; partA = triangle_triangle_partition(A.segment,B.segment)
          elseif is_line_segment(A) and is_triangle(B) then
            action="lt_A"; partA = line_segment_triangle_clip(A.segment,B.segment)
          elseif is_triangle(A) and is_line_segment(B) then
            action="tl_B"; partB = line_segment_triangle_clip(B.segment,A.segment)
          elseif is_line_segment(A) and is_line_segment(B) then
            action="ll_A"; partA = line_segment_line_segment_partition(A.segment,B.segment)
          end

          local sigA, sigB = fragment_signature(A, eps_local), fragment_signature(B, eps_local)
          local key = sigA.."|"..sigB.."|"..(action or "none")

          if attempted[key] then
            j=j+1
          else
            local function process(target, target_index, part, sigOther)
              if not part then return false end
              local frags = fragments_from_partition_result(part, target)
              if #frags==0 then return false end

local kept = {}
for _,f in ipairs(frags) do
  local sig = fragment_signature(f, eps_local)   -- stable
  local uid = f.__id                             -- unique for this frag
  -- Dedup by geometry (sig), but allow multiple frags with different uid
  if not global_seen[sig] then
    global_seen[sig] = true
    kept[#kept+1] = f
  elseif not f.__kept then
    -- allow second fragment with same sig if it has a distinct uid
    kept[#kept+1] = f
    f.__kept = true
  end
end

              if #kept==0 then return false end
              splice_replace_at(working, target_index, kept)
              return true
            end

            local did = false
            if partA then did = process(A,i,partA,sigB) end
            if not did and partB then did = process(B,j,partB,sigA) end
            if not did then
              attempted[key] = true   -- only mark if no change
              j=j+1
            else
              changed=true; i=math.max(1,i-1); break
            end
          end
        end
      end
      i=i+1
    end
  end

  -- ---------------------------------------------------------------
  -- replace items with working
  -- ---------------------------------------------------------------
  for k=#items,1,-1 do items[k]=nil end
  for _,v in ipairs(working) do items[#items+1]=v end

  -- ---------------------------------------------------------------
  -- occlusion graph + SCC topo sort
  -- ---------------------------------------------------------------
  local n=#items
  local bboxes,graph={},{}
  for i=1,n do bboxes[i]={get_bbox(items[i])}; graph[i]={} end
  for i=1,n-1 do
    for j=i+1,n do
      if bboxes_overlap(bboxes[i],bboxes[j]) then
        local r=cmp(items[i],items[j])
        if r==true then table.insert(graph[i],j)
        elseif r==false then table.insert(graph[j],i) end
      end
    end
  end

  local index,stack,indices,lowlink,onstack,sccs=0,{}, {}, {}, {}, {}
  for i=1,n do indices[i],lowlink[i]=-1,-1 end
  local function dfs(v)
    indices[v],lowlink[v]=index,index; index=index+1
    stack[#stack+1]=v; onstack[v]=true
    for _,w in ipairs(graph[v]) do
      if indices[w]==-1 then dfs(w); lowlink[v]=math.min(lowlink[v],lowlink[w])
      elseif onstack[w] then lowlink[v]=math.min(lowlink[v],indices[w]) end
    end
    if lowlink[v]==indices[v] then
      local scc={}
      while true do
        local w=table.remove(stack); onstack[w]=false
        scc[#scc+1]=w
        if w==v then break end
      end
      sccs[#sccs+1]=scc
    end
  end
  for v=1,n do if indices[v]==-1 then dfs(v) end end

  local scc_index,scc_graph,indeg={}, {}, {}
  for i,comp in ipairs(sccs) do
    for _,v in ipairs(comp) do scc_index[v]=i end
    scc_graph[i],indeg[i]={},0
  end
  for v=1,n do
    for _,w in ipairs(graph[v]) do
      local si,sj=scc_index[v],scc_index[w]
      if si~=sj then table.insert(scc_graph[si],sj); indeg[sj]=indeg[sj]+1 end
    end
  end

  local queue,sorted={},{}
  for i=1,#sccs do if indeg[i]==0 then queue[#queue+1]=i end end
  while #queue>0 do
    local i=table.remove(queue,1)
    for _,v in ipairs(sccs[i]) do sorted[#sorted+1]=items[v] end
    for _,j in ipairs(scc_graph[i]) do
      indeg[j]=indeg[j]-1
      if indeg[j]==0 then queue[#queue+1]=j end
    end
  end

  return sorted
end









local function reverse_inplace(t)
    local n = #t
    for i = 1, math.floor(n/2) do
        t[i], t[n-i+1] = t[n-i+1], t[i]
    end
end

local occlusion_sort_segments = require "lua-tikz3dtools-occlusion"
local function display_segments()
    -- First, reciprocate all points by homogeneous coordinates
    for _, segment in ipairs(segments) do
        local pts = {}
        
        -- Reciprocate each point and skip those that are out of bounds
        for _, P in ipairs(segment.segment) do
            local R = mm.reciprocate_by_homogenous({P})[1]
            
            -- Skip points outside the threshold range (culling logic)
            if math.abs(R[1]) > 150 or math.abs(R[2]) > 150 or R[3] > 0 then
                -- Mark segment to be skipped
                segment.skip = true
                break
            end
            
            -- Add reciprocated point to the list
            table.insert(pts, R)
        end
        
        -- Update the segment with the reciprocated points
        segment.segment = pts
    end

    -- Now perform the topological sorting, only including segments that are not skipped
    local filtered_segments = {}
    for _, segment in ipairs(segments) do
        if not segment.skip then
            table.insert(filtered_segments, segment)
        end
    end
    
    -- Perform sorting after filtering out skipped segments
    filtered_segments = topo_sort_with_cycles(filtered_segments, occlusion_sort_segments, 16)
    
    -- Reverse the order after sorting
    reverse_inplace(filtered_segments)

    -- Iterate through the sorted segments for rendering
    for _, segment in ipairs(filtered_segments) do
        -- Handle point segments
        if segment.type == "point" and not segment.name then
            local P = segment.segment[1]
            tex.sprint(string.format(
                "\\path[%s] (%f,%f) circle[radius = 0.06];",
                segment.filloptions,
                P[1], P[2]
            ))
        end

        if segment.type == "point" and segment.name then
            local P = segment.segment[1]
            tex.sprint(string.format(
                "\\node at (%f,%f) {%s};",
                P[1], P[2]
                ,segment.name
            ))
        end
        
        -- Handle line segments
        if segment.type == "line segment" then 
            local S, E = segment.segment[1], segment.segment[2]
            tex.sprint(string.format(
                "\\path[%s] (%f,%f) -- (%f,%f);",
                segment.drawoptions, 
                S[1], S[2], 
                E[1], E[2]
            ))
        end
        
        -- Handle triangle segments
        if segment.type == "triangle" then 
            local P, Q, R = segment.segment[1], segment.segment[2], segment.segment[3]
            tex.sprint(string.format(
                "\\path[%s] (%f,%f) -- (%f,%f) -- (%f,%f) -- cycle;",
                segment.filloptions,
                P[1], P[2], 
                Q[1], Q[2], 
                R[1], R[2]
            ))
        end
    end
    
    -- Clear the segments array after processing
    segments = {}
end

register_tex_cmd("displaysegments", function() display_segments() end, { })


local function make_object(name, tbl)
    local obj = {}
    obj[name] = tbl
    return obj
end

local function set_matrix(hash)
    local transformation = single_string_expression(hash.transformation)
    local name = hash.name
    local tbl = make_object(name, transformation)
    for k, v in pairs(tbl) do lua_tikz3dtools_parametric.math[k] = v end
end
register_tex_cmd(
    "setobject", 
    function()
        set_matrix{
            name           = token.get_macro("luatikztdtools@p@m@name"),
            transformation = token.get_macro("luatikztdtools@p@m@transformation"),
        } 
    end,
    { }
)