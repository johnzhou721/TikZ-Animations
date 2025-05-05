# Pline-vec

Pline-vec is a name which reflects the original scope of this project. 
It was initially to draw planes and intersections, and also enable 
people to draw "on" planes with \pgflowlevelsynccm.

I might rename it to something more general later, since it now
has a broader scope.

## Goals

1. Create a parametric surface grapher where the user inputs the parametric equation of a surface, and the surface is automatically drawn as a triangulated mesh, which is z-buffered properly. A further goal is to be able to z-buffer multiple triangulated mesh surfaces at once.

2. Enable euler angle rotations of the main viewing perspective.

3. Have an Euler angle transformation matrix that can be used inside of a path in tikz.

4. graph intersecting planes, and draw things on them using \pgflowlevelsynccm

5. Conveniently, this project has also forced me to use some nice commands for doing 3D algebra, which are in pv-math.