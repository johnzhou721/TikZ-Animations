# pline-vec

**pline-vec** is a Lua-based 3D vector geometry and rendering engine designed to produce high-quality, depth-sorted TikZ graphics. Leveraging Lua's computational capabilities, pline-vec facilitates the creation of mathematically precise and visually accurate 3D diagrams, including intersecting planes, parametric surfaces, curves, and solids.

---

## Current Capabilities

### Vector and Linear Algebra Operations
- Comprehensive 3D vector arithmetic: dot product, cross product, normalization.
- Construction and application of rotation matrices, including ZYZ Euler angles.
- Computation of orthogonal vectors and normal vectors for geometric primitives.

### Plane Geometry and Clipping
- Definition of planes via normal equations.
- Robust computation of plane intersections.
- Automatic clipping of intersection polygons to bounding volumes.
- Angular sorting of polygon vertices around the centroid for correct path ordering.

### Parametric Surfaces and Curve Rendering
- Parametric definitions for surfaces and curves supported via Lua functions.
- Sampling and tessellation into triangle meshes for surfaces.
- Painter’s algorithm-style depth sorting of triangles and curve segments to handle occlusion.

---

## Roadmap and Remaining Work

- **Automated Plane-Plane Intersection**: Implement functionality to compute intersection lines of two or more planes and integrate resulting line segments into the TikZ output.

---

## Estimated Completion Timeline

| Milestone                       | Estimated Timeframe  |
|--------------------------------|---------------------|
| Plane-plane intersection logic | >2–4 months           |

Total estimated time: **2 to 4 months**.

---
