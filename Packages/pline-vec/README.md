# Pline‑Vec

Pline‑Vec began as a toolkit for drawing planes, computing their intersections, and enabling “on‑plane” drawing via `\pgflowlevelsynccm`. Over time it has grown into a more general coordinate‑transformation and surface‑generation package. (The name may evolve to reflect its expanded scope.)

## Current Features

1. **Parametric Surface Grapher**  
   - Accepts arbitrary parametric equations and user‑supplied parameters  
   - Automatically triangulates the surface into a mesh  
   - **Performs a true Z‑buffer pass on one or more meshes** to render correct depth ordering  
   - **Note:** triangles are currently sorted by centroid only; a more robust depth‑plus‑adjacency sorter is forthcoming  

2. **Euler‑Angle Rotation Matrix**  
   - Provides a reusable matrix macro for any TikZ path  
   - Applies rotations to the coordinate frame *and* to individual path segments  

3. **Intersecting Planes & On‑Plane Drawing**  
   - Supports manual graphing of plane intersections using `spath3`  
   - Allows “on‑plane” rendering with `\pgflowlevelsynccm`  
   - **⚠️ Automated sorting of intersection segments is still under development**—this remains a challenging problem and will be tackled in a future release.

4. **LuaTeX Integration**  
   - Core algorithms are being ported into Lua for improved performance and maintainability  
   - Leverages Lua’s numerical capabilities to accelerate mesh generation and sorting  

## Roadmap

| Deliverable                         | Status                        | ETA                |
|-------------------------------------|-------------------------------|--------------------|
| **Package Documentation**           | Not started                   | 1–2 months         |
| **Parametric Surface Generator**    | ✓ Z‑buffer for single & multiple meshes implemented | < 1 month          |
| **Rotation Matrix**                 | ✓ Complete and tested         | —                  |
| **Plane‑Segment Sorter**            | Manual via `spath3`           | 1–3 months         |
| **Lua Macro Rewrite**               | Planning stage                | 2–4 months         |

> **Total estimated development time:** 3–5 months (tasks overlap and timelines may adjust as needed).

---

*Stay tuned for automated plane‑intersection sorting, and let me know if you’d like to help test the new Z‑buffer routines!*
