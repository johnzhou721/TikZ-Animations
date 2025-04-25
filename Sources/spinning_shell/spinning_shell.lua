function main()
-- generate_frame_tikz.lua
-- This Lua script generates a Beamer frame with a TikZ picture
-- depicting a 3D shell surface. It uses:
--   • Mesh generation from a (u,v) grid,
--   • Normal computation and reorientation based on an inner shell,
--   • Color assignment (yellow if normal·camera ≥ 0, else purple!80),
--   • Painter’s algorithm sorting via maximum vertex depth and, for adjacent (shared–edge) triangles,
--     a plane-distance comparison of unique vertices.
--
-- Usage: Run this file with dofile("generate_frame_tikz.lua") in a LuaTeX run.
-- The output is printed via tex.print and can be directly included in your document.

---------------------------
-- Vector Utility Functions
---------------------------
local function vec_add(a, b)
  return { a[1] + b[1], a[2] + b[2], a[3] + b[3] }
end

local function vec_sub(a, b)
  return { a[1] - b[1], a[2] - b[2], a[3] - b[3] }
end

local function vec_dot(a, b)
  return a[1]*b[1] + a[2]*b[2] + a[3]*b[3]
end

local function vec_cross(a, b)
  return {
    a[2]*b[3] - a[3]*b[2],
    a[3]*b[1] - a[1]*b[3],
    a[1]*b[2] - a[2]*b[1]
  }
end

local function vec_scale(a, s)
  return { a[1]*s, a[2]*s, a[3]*s }
end

local function vec_length(a)
  return math.sqrt(a[1]^2 + a[2]^2 + a[3]^2)
end

-- Check approximate equality between two vectors (with a tolerance)
local function vectors_close(a, b, tol)
  tol = tol or 1e-6
  return math.abs(a[1] - b[1]) < tol and math.abs(a[2] - b[2]) < tol and math.abs(a[3] - b[3]) < tol
end

-- Check if a vector exists in a list of vectors (using approximate equality)
local function in_list(vec, list)
  for _, v in ipairs(list) do
    if vectors_close(vec, v) then return true end
  end
  return false
end

-- Create a linearly spaced array of numbers
local function linspace(start_val, stop_val, num)
  local arr = {}
  if num == 1 then
    arr[1] = start_val
  else
    local step = (stop_val - start_val) / (num - 1)
    for i = 1, num do
      arr[i] = start_val + (i - 1) * step
    end
  end
  return arr
end

---------------------------
-- Parameters and Settings
---------------------------
local scale = 15.0
local usamples, vsamples = 20, 10
local ustart, uend = 10.0, 51.0
local vstart, vend = 0.0, 2 * math.pi

-- Camera parameters (convert angles to radians)
local az_deg, el_deg = 130+rotation, 15
local az = math.rad(az_deg)
local el = math.rad(el_deg)
local camera = { math.sin(az)*math.cos(el), -math.cos(az)*math.cos(el), math.sin(el) }

---------------------------
-- Shell and Inner Shell Functions
---------------------------
local function shell_point(u, v)
  local u1 = u / 100.0
  local x = 0.05 * (1 - u1) * (3 + math.cos(v)) * math.cos(4 * math.pi * u1)
  local y = 0.05 * (1 - u1) * (3 + math.cos(v)) * math.sin(4 * math.pi * u1)
  local z = -0.05 * (3*u1 + (1 - u1) * math.sin(v))
  return { x, y, z }
end

local function innershell_point(u)
  local u1 = u / 100.0
  local x = 0.05 * (1 - u1) * 3 * math.cos(4 * math.pi * u1)
  local y = 0.05 * (1 - u1) * 3 * math.sin(4 * math.pi * u1)
  local z = -0.05 * 3 * u1
  return { x, y, z }
end

---------------------------
-- Build Mesh (Generate Triangles)
---------------------------
local triangles = {}
local us = linspace(ustart, uend, usamples + 1)
local vs = linspace(vstart, vend, vsamples + 1)
local du = us[2] - us[1]
local dv = vs[2] - vs[1]

for i = 1, usamples do
  for j = 1, vsamples do
    local u = us[i]
    local v = vs[j]
    local A = shell_point(u, v)
    local B = shell_point(u + du, v)
    local C = shell_point(u, v + dv)
    local D = shell_point(u + du, v + dv)
    table.insert(triangles, { verts = { A, C, D }, u_mid = u + du/3 })
    table.insert(triangles, { verts = { A, B, D }, u_mid = u + 2*du/3 })
  end
end

---------------------------
-- Helper Functions for Triangle Processing
---------------------------
local function centroid(tri)
  local v = tri.verts
  return { (v[1][1] + v[2][1] + v[3][1]) / 3,
           (v[1][2] + v[2][2] + v[3][2]) / 3,
           (v[1][3] + v[2][3] + v[3][3]) / 3 }
end

local function max_depth(tri)
  local max_val = -math.huge
  for i = 1, 3 do
    local d = vec_dot(tri.verts[i], camera)
    if d > max_val then max_val = d end
  end
  return max_val
end

local function share_two(t1, t2)
  local count = 0
  for i = 1, 3 do
    for j = 1, 3 do
      if vectors_close(t1.verts[i], t2.verts[j]) then
        count = count + 1
      end
    end
  end
  return count >= 2
end

local function get_shared_vertices(t1, t2)
  local shared = {}
  for i = 1, 3 do
    for j = 1, 3 do
      if vectors_close(t1.verts[i], t2.verts[j]) then
        if not in_list(t1.verts[i], shared) then
          table.insert(shared, t1.verts[i])
        end
      end
    end
  end
  return shared
end

---------------------------
-- Compute Normals and Assign Colors
---------------------------
for _, tri in ipairs(triangles) do
  local a, b, c = tri.verts[1], tri.verts[2], tri.verts[3]
  local ab = vec_sub(b, a)
  local ac = vec_sub(c, a)
  local n = vec_cross(ab, ac)
  local cent = centroid(tri)
  local inner = innershell_point(tri.u_mid)
  if vec_dot(n, vec_sub(cent, inner)) < 0 then
    n = vec_scale(n, -1)
  end
  tri.normal = n
  tri.view_dp = vec_dot(n, camera)
  if tri.view_dp >= 0 then
    tri.color = "yellow"
  else
    tri.color = "purple!80"
  end
end

---------------------------
-- Plane-distance Function For Adjacent Triangles
---------------------------
local function plane_distance(tri_plane, point)
  local p0 = tri_plane.verts[1]
  local n = tri_plane.normal
  local len_n = vec_length(n)
  if len_n == 0 then return 0 end
  local dot_nc = vec_dot(n, camera)
  local sign = (dot_nc >= 0) and 1 or -1
  local diff = vec_sub(point, p0)
  return sign * vec_dot(n, diff) / len_n
end

---------------------------
-- Triangle Comparator
---------------------------
local function tri_less(t1, t2)
  if share_two(t1, t2) then
    local shared = get_shared_vertices(t1, t2)
    local uniq1, uniq2 = nil, nil
    for i = 1, 3 do
      local found = false
      for _, s in ipairs(shared) do
        if vectors_close(t1.verts[i], s) then
          found = true
          break
        end
      end
      if not found then
        uniq1 = t1.verts[i]
        break
      end
    end
    for i = 1, 3 do
      local found = false
      for _, s in ipairs(shared) do
        if vectors_close(t2.verts[i], s) then
          found = true
          break
        end
      end
      if not found then
        uniq2 = t2.verts[i]
        break
      end
    end
    -- If for any reason the unique vertex isn't found, fall back on max depth.
    if not (uniq1 and uniq2) then return max_depth(t1) < max_depth(t2) end
    local d1 = plane_distance(t2, uniq1)
    local d2 = plane_distance(t1, uniq2)
    return d1 < d2  -- triangle with the smaller (more behind) distance comes first
  else
    return max_depth(t1) < max_depth(t2)
  end
end

table.sort(triangles, tri_less)

---------------------------
-- Output via tex.print
---------------------------
tex.print(string.format("\\begin{frame}[fragile]"))
tex.print("  \\centering")
tex.print(string.format("  \\tdplotsetmaincoords{90-%f}{%f}\\begin{tikzpicture}[tdplot_main_coords]", el_deg,az_deg))
tex.print("\\path[tdplot_screen_coords](-\\textwidth/2,-\\textheight/2) rectangle (\\textwidth/2,\\textheight/2);\\clip[tdplot_screen_coords]")
tex.print("(-\\textwidth/2,-\\textheight/2) rectangle (\\textwidth/2,\\textheight/2);")
for _, tri in ipairs(triangles) do
  local a, b, c = tri.verts[1], tri.verts[2], tri.verts[3]
  local line = string.format("    \\filldraw[fill=%s,draw=black] (%.5f,%.5f,%.5f) -- (%.5f,%.5f,%.5f) -- (%.5f,%.5f,%.5f) -- cycle;",
    tri.color,
    a[1]*scale, a[2]*scale, a[3]*scale,
    b[1]*scale, b[2]*scale, b[3]*scale,
    c[1]*scale, c[2]*scale, c[3]*scale)
  tex.print(line)
end

tex.print("  \\end{tikzpicture}")
tex.print("\\end{frame}")

-- Optionally, you can print a message to the log:
texio.write_nl("Wrote frame_tikz output via tex.print")
end