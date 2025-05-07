# Pline-Vec

Pline-Vec is a name reflecting this project’s original scope: drawing planes and intersections, and enabling “on‑plane” drawing via `\pgflowlevelsynccm`. The scope has since broadened, and the name may change later.

## Goals

1. **Parametric surface grapher**  
   - User inputs a parametric equation  
   - Automatically triangulate into a mesh  
   - Z-buffer each mesh (and eventually multiple meshes)    

2. **Euler transformation matrix**  
   - Provide a matrix macro for use inside any TikZ path. This also enables rotating the coordinate frame, as well as sub frames. 

4. **Plane intersections & on-plane drawing**  
   - Graph intersecting planes  
   - Draw on planes with `\pgflowlevelsynccm` 
   - Eventually this will be automated to sort the intersection segments automatically, but for now it is done manually, due to the complexity of the problem. 

5. **pv-math utilities**  
   - 3D algebra macros in `pv-math`  

## Timeline & Process

| Deliverable                    | Tasks                                                      | Timeline                |
|--------------------------------|------------------------------------------------------------|-------------------------|
| **1. Documentation**           | Write README, package docs, annotated examples, API guide  | 1–2 months (from start) |
| **2. Parametric Surface Generator** | Implement Lua triangulation, mesh Z‑buffer, TikZ integration | 2–3 months              |
| **3. Plane Segment Sorter**    | Develop depth & adjacency‑based sorting macros for planes  | 1–2 months              |
| **4. Additional Macro Commands** | Create utility macros (vector ops, matrix transforms, keys) | 1–2 months              |

_Total estimated time: 3–9 months_ (these timeframes overlap a bit, and might need to change if I run into roadblocks.)