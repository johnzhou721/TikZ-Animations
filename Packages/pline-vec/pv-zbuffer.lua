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

-- Clip a 2D polygon 'subject' against the half‐plane on the left of edge A→B
local function clipPolygon(subject, A, B)
  local out = {}
  local n = #subject
  for i=1,n do
    local P = subject[i]
    local Q = subject[(i % n) + 1]
    local inP = orient2d(A, B, P) >= 0
    local inQ = orient2d(A, B, Q) >= 0
    if inP and inQ then
      -- both inside
      table.insert(out, Q)
    elseif inP and not inQ then
      -- exiting: keep intersection
      local I = lineIntersect(P, Q, A, B)
      if I then table.insert(out, I) end
    elseif not inP and inQ then
      -- entering: keep intersection then Q
      local I = lineIntersect(P, Q, A, B)
      if I then table.insert(out, I) end
      table.insert(out, Q)
    end
    -- if both outside, emit nothing
  end
  return out
end


-- Build a 2D basis e1,e2 orthogonal to viewDir (must be unit length)
local function makeBasis(viewDir)
  -- choose a not-quite-colinear up vector
  local up = math.abs(viewDir[3]) < 0.9 and {0,0,1} or {0,1,0}
  -- e1 = normalize(viewDir × up)
  local e1 = {
    viewDir[2]*up[3] - viewDir[3]*up[2],
    viewDir[3]*up[1] - viewDir[1]*up[3],
    viewDir[1]*up[2] - viewDir[2]*up[1],
  }
  local len1 = math.sqrt(e1[1]^2 + e1[2]^2 + e1[3]^2)
  e1 = { e1[1]/len1, e1[2]/len1, e1[3]/len1 }
  -- e2 = viewDir × e1
  local e2 = {
    viewDir[2]*e1[3] - viewDir[3]*e1[2],
    viewDir[3]*e1[1] - viewDir[1]*e1[3],
    viewDir[1]*e1[2] - viewDir[2]*e1[1],
  }
  return e1, e2
end

-- Project a 3D point p into the plane basis (e1,e2) → 2D coords
local function proj2D(p, e1, e2)
  return { p[1]*e1[1] + p[2]*e1[2] + p[3]*e1[3],
           p[1]*e2[1] + p[2]*e2[2] + p[3]*e2[3] }
end

-- (Re-use orient2d, lineIntersect, clipPolygon, triIntersection2D from before,
--  but now they work on generic 2D coords.)

-- Compute intersection‐witness polygon in the projected plane    
local function triIntersection2D_gen(tA, tB, e1, e2)
  -- make 2D polys
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
  -- clip against each edge of B in 2D
  for _, edge in ipairs({{2,3},{3,1},{1,2}}) do
    local a, b = Bpts[edge[1]], Bpts[edge[2]]
    poly = clipPolygon(poly, a, b)
    if #poly == 0 then return {} end
  end
  return poly
end

-- Recover depth along viewDir at witness point:
-- for point P (in world coords), depth = dot(P, viewDir)
local function depthAtPoint(tri, x2, y2, e1, e2, viewDir)
  -- we need the 3D witness point: x2*e1 + y2*e2 + t*viewDir for some t,
  -- but any point on the intersection plane has form W = C + x2*e1 + y2*e2,
  -- where C is arbitrary origin in that plane.  To get its world‐space Z,
  -- it's simplest to intersect the viewing line through (x2,y2) with the triangle's plane:
  -- (same as zOnPlane but for general viewDir).  However, instead we can:
  --   1. Recover W approximately by barycentric lifting on triangle,
  --   2. Then dot(W, viewDir).
  -- For simplicity: fallback to centroid‐depth if general plane intersection is too involved.
  local cx, cy, cz = (tri[1][1]+tri[2][1]+tri[3][1])/3,
                     (tri[1][2]+tri[2][2]+tri[3][2])/3,
                     (tri[1][3]+tri[2][3]+tri[3][3])/3
  return cx*viewDir[1] + cy*viewDir[2] + cz*viewDir[3]
end

-- Factory: returns comparator(a,b) given viewDir
local function makeTriangleComparator(viewDir)
  -- normalize viewDir
  local vdlen = math.sqrt(viewDir[1]^2 + viewDir[2]^2 + viewDir[3]^2)
  viewDir = { viewDir[1]/vdlen, viewDir[2]/vdlen, viewDir[3]/vdlen }
  local e1,e2 = makeBasis(viewDir)

  return function(a, b)
    -- 1) overlap in projected plane?
    local poly = triIntersection2D_gen(a, b, e1, e2)
    if #poly == 0 then
      -- no overlap → compare centroid depths
      local da = depthAtPoint(a, 0,0, e1,e2, viewDir)
      local db = depthAtPoint(b, 0,0, e1,e2, viewDir)
      return da > db
    else
      -- use first witness
      local wx, wy = poly[1][1], poly[1][2]
      local da = depthAtPoint(a, wx, wy, e1,e2, viewDir)
      local db = depthAtPoint(b, wx, wy, e1,e2, viewDir)
      -- return true if a is farther (draw it first)
      return da > db
    end
  end
end

local function segmentComparator(sa, sb)
  return makeTriangleComparator(observer)(
    { sa[1], sa[2], sa[3] },
    { sb[1], sb[2], sb[3] }
  )
end

-- Usage:
-- local cmp = makeTriangleComparator({0,0,1})     -- for orthographic along +Z
-- table.sort(triangles, cmp)                      -- triangles: array of {{x,y,z},…}




segments = {}

function append_surface(u_start, u_end, u_samples,
                        v_start, v_end, v_samples,
                        fx, fy, fz)

    local u_step = (u_end - u_start) / (u_samples  - 1)
    local v_step = (v_end - v_start) / (v_samples  - 1)

    local gx = load("return function(u,v) return " .. fx .. " end")()
    local gy = load("return function(u,v) return " .. fy .. " end")()
    local gz = load("return function(u,v) return " .. fz .. " end")()

    local function surface(u, v)
        return { gx(u,v), gy(u,v), gz(u,v) }
    end

    for i = 0, u_samples-2 do
        local u = u_start + i * u_step
        local color_frac = (u - u_start) / (u_end - u_start)

        for j = 0, v_samples-2 do
            local v = v_start + j * v_step

            local A = surface(u,           v)
            local B = surface(u + u_step,  v)
            local C = surface(u,           v + v_step)
            local D = surface(u + u_step,  v + v_step)

            -- triangle A–B–D
            local mid1 = pv_average(A, B, D)
            local dp1  = pv_dot_product(observer, mid1)
            table.insert(segments, { A, B, D, color_frac })

            -- triangle A–C–D
            local mid2 = pv_average(A, C, D)
            local dp2  = pv_dot_product(observer, mid2)
            table.insert(segments, { A, C, D, color_frac })
        end
    end
end


function render_segments()
  table.sort(segments, segmentComparator)

  for _, seg in ipairs(segments) do
    local _, P, Q, R, col = table.unpack(seg)
    local P, Q, R, col = table.unpack(seg)
    local pct = math.floor(100 * col)
    tex.print(string.format("\\SetColor{%d}", pct))
    tex.print("\\draw[line join=round, preaction={fill=MyColor}]")
    tex.print(string.format(
      "(%f,%f,%f) -- (%f,%f,%f) -- (%f,%f,%f) -- cycle;",
      P[1],P[2],P[3],
      Q[1],Q[2],Q[3],
      R[1],R[2],R[3]
    ))
  end

  segments = {}
end

