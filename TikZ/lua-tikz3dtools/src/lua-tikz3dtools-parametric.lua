-- lua-tikz3dtools-parametric.lua

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
            table.insert(
                segments, 
                { 
                    segment      = the_segment1, 
                    filloptions = filloptions, 
                    type         = "triangle" 
                }
            )
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






local function get_bbox(primitive)
    local minX, maxX = math.huge, -math.huge
    local minY, maxY = math.huge, -math.huge
    for _, P in ipairs(primitive.segment) do
        local x, y = P[1], P[2]
        if x < minX then minX = x end
        if x > maxX then maxX = x end
        if y < minY then minY = y end
        if y > maxY then maxY = y end
    end
    return minX, maxX, minY, maxY
end

local function bboxes_overlap(b1, b2)
    local minX1, maxX1, minY1, maxY1 = table.unpack(b1)
    local minX2, maxX2, minY2, maxY2 = table.unpack(b2)
    return not (maxX1 < minX2 or maxX2 < minX1 or maxY1 < minY2 or maxY2 < minY1)
end

local function topo_sort_with_cycles(items, cmp, max_depth)
    -- Step 1: Precompute bounding boxes
    local bboxes = {}
    for i, primitive in ipairs(items) do
        bboxes[i] = { get_bbox(primitive) }
    end

    -- Step 2: Build graph based on bounding-box overlap + comparison
    local graph = {}
    for i = 1, #items do graph[i] = {} end

    for i = 1, #items - 1 do
        for j = i + 1, #items do
            if bboxes_overlap(bboxes[i], bboxes[j]) then
                local r = cmp(items[i], items[j])
                if r == true then
                    table.insert(graph[i], j)
                elseif r == false then
                    table.insert(graph[j], i)
                end
            end
            -- otherwise, boxes don't overlap → skip comparison
        end
    end

    -- Step 3: Tarjan's SCC algorithm (unchanged)
    local index, stack = 0, {}
    local indices, lowlink, onstack = {}, {}, {}
    local sccs = {}

    for i = 1, #items do
        indices[i], lowlink[i] = -1, -1
    end

    local function dfs(v)
        indices[v], lowlink[v] = index, index
        index = index + 1
        table.insert(stack, v)
        onstack[v] = true

        for _, w in ipairs(graph[v]) do
            if indices[w] == -1 then
                dfs(w)
                lowlink[v] = math.min(lowlink[v], lowlink[w])
            elseif onstack[w] then
                lowlink[v] = math.min(lowlink[v], indices[w])
            end
        end

        if lowlink[v] == indices[v] then
            local scc = {}
            while true do
                local w = table.remove(stack)
                onstack[w] = false
                table.insert(scc, w)
                if w == v then break end
            end
            table.insert(sccs, scc)
            if #scc > 1 then
                print("Cycle detected involving primitives: ", table.concat(scc, ", "))
            end
        end
    end

    for v = 1, #items do
        if indices[v] == -1 then dfs(v) end
    end

    -- Step 4: SCC graph and indegree
    local scc_index, scc_graph, indeg = {}, {}, {}
    for i, comp in ipairs(sccs) do
        for _, v in ipairs(comp) do scc_index[v] = i end
        scc_graph[i], indeg[i] = {}, 0
    end

    for v = 1, #items do
        for _, w in ipairs(graph[v]) do
            local si, sj = scc_index[v], scc_index[w]
            if si ~= sj then
                table.insert(scc_graph[si], sj)
                indeg[sj] = indeg[sj] + 1
            end
        end
    end

    -- Step 5: Topological sort of SCCs
    local queue, sorted_sccs = {}, {}
    for i = 1, #sccs do if indeg[i] == 0 then table.insert(queue, i) end end

    while #queue > 0 do
        local i = table.remove(queue, 1)
        for _, v in ipairs(sccs[i]) do
            table.insert(sorted_sccs, items[v])
        end
        for _, j in ipairs(scc_graph[i]) do
            indeg[j] = indeg[j] - 1
            if indeg[j] == 0 then table.insert(queue, j) end
        end
    end

    return sorted_sccs
end









-- Example:
-- segments = topo_sort_with_cycles(segments, occlusion_sort_segments)

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
    filtered_segments = topo_sort_with_cycles(filtered_segments, occlusion_sort_segments, 40)
    
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


function make_object(name, tbl)
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