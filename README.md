# Ti*k*Z-Animations

## Overview

Welcome to my public repository, Ti*k*Z-Animations. This is a curated 
collection of my artwork in Ti*k*Z, focused mainly on animations,
though I will also include some still diagrams as well.

## Repository Structure

- **Animations/**  
  Prebuilt `.gif` animations. (I use ezgif.com/maker to convert my PDF flip‑books into GIFs.)

- **Sources/**  
  LaTeX (and Lua/Python) source code for selected animations. As my skills evolved, some early files were retired and are not included here.

- **Packages/**  
  Development code for custom Ti*k*Z packages (e.g. `pline-vec.sty`) that power my 3D and animation work.

## Featured Animation

![Elliptic Spherical Möbius Transformation](Animations/elliptic_spherical_mobius_transformation.gif)

*Elliptic Spherical Möbius Transformation*

## Technical Highlights

- **Pline‑Vec**  
  - Now supports true Z‑buffering of multiple surfaces (triangles are currently sorted by centroid; a more robust sorter is in progress).  
  - Completed Euler‑angle rotation matrix for both coordinate frames and individual path segments.  
  - Manual plane‑intersection drawing via `spath3`; automated intersection sorting remains a future challenge.

- **AnimateTeX**  
  A Python‑driven LaTeX animation pipeline. Frames are compiled incrementally so you can preview progress as the animation builds—no more opaque TeX loops!

- **Community Contributions**  
  Active on [TeX Stack Exchange](https://tex.stackexchange.com/users/319072/jasper) and [TikZ.net](https://tikz.net/author/jasper/). I’m grateful for all the help I’ve received and pay it forward whenever I can.

## Disclaimer

This repository is licensed under the MIT No Attribution (MIT-0) 
License. You are free to use, modify, and distribute the content without 
any attribution requirements. For more details, refer to the 
[MIT-0 License](https://opensource.org/license/mit-0/).

That being said, I always do appreciate credit, but it is not 
*required*.