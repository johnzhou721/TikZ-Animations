# Pline-Vec

Pline-Vec is a name reflecting this project’s original scope: drawing planes and intersections, and enabling “on‑plane” drawing via `\pgflowlevelsynccm`. The scope has since broadened, and the name may change later. Now the scope also includes broader coordinate transformations, as well as surface generation.

## Goals

1. **Parametric surface grapher**  
   - User inputs a parametric equation as well as other necessary information
   - Automatically triangulate into a mesh  
   - Z-buffer each mesh (and eventually multiple meshes)    

2. **Euler transformation matrix**  
   - Provide a matrix macro for use inside any TikZ path. This also enables rotating the coordinate frame, as well as **paths** (not sub-frames). 

4. **Plane intersections & on-plane drawing**  
   - Graph intersecting planes  
   - Draw on planes with `\pgflowlevelsynccm` 
   - Eventually this will be automated to sort the intersection segments automatically, but for now it is done manually with spath3, due to the complexity of the problem. 

5. **pv-math utilities**  
   - 3D algebra macros in `pv-math`  

## Timeline & Process

| Deliverable                    | Tasks                                                      | Timeline                |
|--------------------------------|------------------------------------------------------------|-------------------------|
| **1. Documentation**           | Write README, package docs, annotated examples  | 1–2 months (from when I start) |
| **2. Parametric Surface Generator** | Mesh Z‑buffer | <1month months              |
| **3. Plane Segment Sorter**    | Develop depth & adjacency‑based sorting macros for planes  | 1–3 months              |
| **4. Additional Macro Commands** | Create utility macros (vector ops, matrix transforms, keys) | ~1 months              |

_Total estimated time: 3–5 months_ (these timeframes overlap a bit, and might need to change if I run into roadblocks.)