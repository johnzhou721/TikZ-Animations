--[[
Credit: I had AI implement the triangle sorting algorithm from
https://math.stackexchange.com/q/5063772/1499599, because I didn't feel like
crunching all the numbers. I might do it myself at some point.
]]

-- 2D orientation: >0 if c is left of a→b
local function orient2d(a, b, c)
  return (b[1]-a[1])*(c[2]-a[2]) - (b[2]-a[2])*(c[1]-a[1])
end

-- Intersect segment P→Q with the infinite line A→B
local function lineIntersect(P, Q, A, B)
  local u = { Q[1]-P[1], Q[2]-P[2] }
  local v = { B[1]-A[1], B[2]-A[2] }
  local det = u[1]*v[2] - u[2]*v[1]
  if math.abs(det) < 1e-8 then return nil end
  local w = { P[1]-A[1], P[2]-A[2] }
  local t = (v[1]*w[2] - v[2]*w[1]) / det
  return { P[1] + t*u[1], P[2] + t*u[2] }
end

-- Clip a 2D polygon 'subject' against the half‑plane on the left of edge A→B
local function clipPolygon(subject, A, B)
  local out = {}
  local n = #subject
  for i = 1, n do
    local P, Q = subject[i], subject[(i % n) + 1]
    local inP, inQ = orient2d(A, B, P) >= 0, orient2d(A, B, Q) >= 0
    if inP and inQ then
      table.insert(out, Q)
    elseif inP and not inQ then
      local I = lineIntersect(P, Q, A, B)
      if I then table.insert(out, I) end
    elseif not inP and inQ then
      local I = lineIntersect(P, Q, A, B)
      if I then table.insert(out, I) end
      table.insert(out, Q)
    end
  end
  return out
end

-- Build a 2D basis e1,e2 orthogonal to viewDir (unit length)
local function makeBasis(viewDir)
  local up = math.abs(viewDir[3]) < 0.9 and {0, 0, 1} or {0, 1, 0}
  local e1 = {
    viewDir[2]*up[3] - viewDir[3]*up[2],
    viewDir[3]*up[1] - viewDir[1]*up[3],
    viewDir[1]*up[2] - viewDir[2]*up[1],
  }
  local len1 = math.sqrt(e1[1]^2 + e1[2]^2 + e1[3]^2)
  e1 = { e1[1]/len1, e1[2]/len1, e1[3]/len1 }
  local e2 = {
    viewDir[2]*e1[3] - viewDir[3]*e1[2],
    viewDir[3]*e1[1] - viewDir[1]*e1[3],
    viewDir[1]*e1[2] - viewDir[2]*e1[1],
  }
  return e1, e2
end

-- Project a 3D point to 2D coords via basis
local function proj2D(p, e1, e2)
  return {
    p[1]*e1[1] + p[2]*e1[2] + p[3]*e1[3],
    p[1]*e2[1] + p[2]*e2[2] + p[3]*e2[3],
  }
end

-- Intersection‑witness polygon for two triangles
local function triIntersection2D_gen(tA, tB, e1, e2)
  local poly = {
    proj2D(tA[1], e1, e2),
    proj2D(tA[2], e1, e2),
    proj2D(tA[3], e1, e2),
  }
  local Bpts = {
    proj2D(tB[1], e1, e2),
    proj2D(tB[2], e1, e2),
    proj2D(tB[3], e1, e2),
  }
  for _, edge in ipairs({{2,3}, {3,1}, {1,2}}) do
    local a, b = Bpts[edge[1]], Bpts[edge[2]]
    poly = clipPolygon(poly, a, b)
    if #poly == 0 then return {} end
  end
  return poly
end

-- Depth at centroid fallback
local function depthCentroid(tri, viewDir)
  local cx = (tri[1][1] + tri[2][1] + tri[3][1]) / 3
  local cy = (tri[1][2] + tri[2][2] + tri[3][2]) / 3
  local cz = (tri[1][3] + tri[2][3] + tri[3][3]) / 3
  return cx*viewDir[1] + cy*viewDir[2] + cz*viewDir[3]
end

-- Factory: triangle comparator closure
local function makeTriangleComparator(viewDir)
  local vd = math.sqrt(viewDir[1]^2 + viewDir[2]^2 + viewDir[3]^2)
  viewDir = { viewDir[1]/vd, viewDir[2]/vd, viewDir[3]/vd }
  local e1, e2 = makeBasis(viewDir)
  return function(a, b)
    local poly = triIntersection2D_gen(a, b, e1, e2)
    if #poly == 0 then
      return depthCentroid(a, viewDir) > depthCentroid(b, viewDir)
    else
      -- use witness point for depth
      local wx, wy = poly[1][1], poly[1][2]
      local da = depthCentroid(a, viewDir)
      local db = depthCentroid(b, viewDir)
      return da > db
    end
  end
end

-- Track last observer to detect changes
local triComparator, lastObserver

-- Lazy update when observer changes
function updateComparator()
  if not observer then return end
  if lastObserver
     and observer[1]==lastObserver[1]
     and observer[2]==lastObserver[2]
     and observer[3]==lastObserver[3] then
    return
  end
  triComparator = makeTriangleComparator(observer)
  lastObserver = {observer[1], observer[2], observer[3]}
end

-- Unified comparator for segments (2 points) & triangles (≥3 points)
function segmentComparator(sa, sb)
  updateComparator()
  local na, nb = #sa, #sb
  local aTri, bTri = na >= 3, nb >= 3
  -- triangle vs triangle
  if aTri and bTri then
    return triComparator(
      {sa[1], sa[2], sa[3]},
      {sb[1], sb[2], sb[3]}
    )
  end
  -- depth of midpoint vs centroid
  local function depth(s, isTri)
    if isTri then
      return depthCentroid(s, observer)
    else
      local m = {
        (s[1][1] + s[2][1]) * 0.5,
        (s[1][2] + s[2][2]) * 0.5,
        (s[1][3] + s[2][3]) * 0.5,
      }
      return m[1]*observer[1] + m[2]*observer[2] + m[3]*observer[3]
    end
  end
  return depth(sa, aTri) > depth(sb, bTri)
end

-- storage for all drawable segments/triangles
segments = {}

-- append a parametric curve as line segments
function append_curve(u_start, u_end, u_samples, fx, fy, fz)
  local u_step = (u_end - u_start) / (u_samples - 1)
  local function makeEvaluator(expr)
    if type(expr) == 'function' then return expr end
    return assert(load('return function(u) return '..expr..' end'))()
  end
  local gx, gy, gz = makeEvaluator(fx), makeEvaluator(fy), makeEvaluator(fz)
  local function curve(u)
    return {gx(u), gy(u), gz(u)}
  end
  for i = 0, u_samples - 2 do
    local u = u_start + i * u_step
    local A, B = curve(u), curve(u + u_step)
    table.insert(segments, {A, B})
  end
end

-- append a parametric surface as two triangles per quad
function append_surface(u_start, u_end, u_samples,
                        v_start, v_end, v_samples,
                        fx, fy, fz)
  local u_step = (u_end - u_start) / (u_samples - 1)
  local v_step = (v_end - v_start) / (v_samples - 1)
  local function makeEvaluator(expr)
    if type(expr) == 'function' then return expr end
    return assert(load('return function(u,v) return '..expr..' end'))()
  end
  local gx, gy, gz = makeEvaluator(fx), makeEvaluator(fy), makeEvaluator(fz)
  local function surface(u,v)
    return {gx(u,v), gy(u,v), gz(u,v)}
  end
  for i = 0, u_samples - 2 do
    local u = u_start + i * u_step
    local cf = (u - u_start) / (u_end - u_start)
    for j = 0, v_samples - 2 do
      local v = v_start + j * v_step
      local A = surface(u, v)
      local B = surface(u + u_step, v)
      local C = surface(u, v + v_step)
      local D = surface(u + u_step, v + v_step)
      table.insert(segments, {A, B, D, cf})
      table.insert(segments, {A, C, D, cf})
    end
  end
end

-- expose globals for TeX macros
pvappendcurve    = append_curve
pvappendsurface  = append_surface
pv_render_segments = function()
  table.sort(segments, segmentComparator)
  for _, seg in ipairs(segments) do
    local n = #seg; local P, Q, R, c = seg[1], seg[2], seg[3], seg[4] or 0
    if n == 2 then
      tex.print(string.format('\\draw[line join=round] (%f,%f,%f)--(%f,%f,%f);',
        P[1], P[2], P[3], Q[1], Q[2], Q[3]
      ))
    else
      tex.print(string.format('\\SetColor{%d}', math.floor(100*c)))
      tex.print('\\draw[line join=round,preaction={fill=MyColor}]')
      tex.print(string.format('(%f,%f,%f)--(%f,%f,%f)--(%f,%f,%f)--cycle;',
        P[1],P[2],P[3],Q[1],Q[2],Q[3],R[1],R[2],R[3]
      ))
    end
  end
  segments = {}
end
