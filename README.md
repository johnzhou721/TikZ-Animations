# Ti*k*Z-Animations

Welcome to **Ti*k*Z-Animations** — a personal hobby project where I explore the expressive side of TeX, using tools like **TikZ**, **Lua**, **MetaPost**, and **ConTeXt** to push the boundaries of what’s possible in technical animation.

This is not a production library (yet), just something I’ve been building and learning from — and I hope you find it interesting or inspiring too.

---

## Project Goals

1. **Create beautiful, mathematical animations in TeX**  
   These animations aren’t just eye candy — they’re built from first principles using custom Lua code for geometry, rendering, and visibility. My aim is to explore how deeply TeX can serve as a creative platform for spatial and mathematical visualization.

2. **Share useful techniques and code**  
   While working on these animations, I’ve developed code that fills some of the gaps in existing TeX graphics systems — especially for 3D rendering, backface culling, projective transformations, and triangle sorting. You’re welcome to borrow from or build on it.

---

## Examples

<table>
<tr>
<td align="center">
<img src="Animations\elliptic_spherical_mobius_transformation.gif" width="240"><br>
<sub><code>Inversion of a sphere via a Möbius transformation</code></sub>
</td>
<td align="center">
<img src="Animations\zooming_in_on_sphere.gif" width="240"><br>
<sub><code>Rotating a 3D shell with painter’s algorithm sorting</code></sub>
</td>
</tr>
<tr>
<td align="center">
<img src="Animations\camera_angle_torus.gif" width="240"><br>
<sub><code>Parametric morph between saddle surfaces</code></sub>
</td>
<td align="center">
<img src="Animations\tre_foil_knot.gif" width="240"><br>
<sub><code>Sorted triangle mesh rendering using Lua</code></sub>
</td>
</tr>
</table>

---

## Technologies Used

- **LuaTeX + TikZ** for low-level drawing control
- **MetaPost + ConTeXt** for smooth rendering and animation output
- **Custom Lua modules** for 3D geometry, matrix math, and triangle sorting

---

## Thank You

**Thank you** for checking out *Ti*k*Z-Animations*.  
I hope you enjoy what you find here.
