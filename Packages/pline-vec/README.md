# tikz-3dgeom

`pline-vec` is a toolkit for 3D visualization in TikZ.

I was motivated to write this package because of things that I wanted to do, but could not do with the standard packages, `tikz-3dplot` and `pgfplots`. For example, `pgfplots` cannot z-buffer multiple surfaces at once, and `tikz-3dplot` does not allow euler angle rotations of the main coordinate frame. Also, neither package can draw intersecting planes properly. `pline-vec` can do all of that, and will also be able to do more.

## Current Features

1. **Parametric Surface Rendering**  
   - Accepts arbitrary parametric equations with user-supplied domains  
   - Automatically triangulates the surface into a mesh  
   - **Performs a Z-buffer-style depth sort across one or more meshes**  
   - _Note:_ Current triangle sort uses centroids only; a robust depth-plus-adjacency pass is in development

2. **Euler-Angle Rotation Matrix**  
   - Provides reusable rotation matrices for 3D transformations  
   - Applies to both coordinate frames and individual TikZ paths  

3. **Plane Intersections & On-Plane Drawing**  
   - Supports manual construction of plane intersections via `spath3`  
   - Enables on-plane drawing with `\pgflowlevelsynccm`  
   - ⚠️ Automatic sorting of intersection segments is still in progress

4. **LuaTeX Integration**  
   - Core algorithms are being ported to Lua for speed and maintainability  

## Roadmap

| Deliverable                         | Status                        | ETA                |
|-------------------------------------|-------------------------------|--------------------|
| **Package Documentation**           | Not started                   | 1–2 months (from start)         |
| **Parametric Surface Generator**    | ✓ Multi-mesh Z-buffer pass done | —          |
| **Rotation Matrix**                 | ✓ Complete and tested         | —                  |
| **Plane-Segment Sorter**            | Manual via `spath3`           | 2–5 months         |
| **Lua Macro Rewrite**               | Planning stage                | 1-2 months         |

> **Estimated development time:** 3–5 months
