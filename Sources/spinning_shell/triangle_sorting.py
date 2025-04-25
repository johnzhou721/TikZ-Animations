"""
Python script to generate a standalone TikZ/LaTeX file of a 3D shell surface,
with improved adjacency sorting using pure plane-distance (no camera projection) for shared-edge triangles,
and overall painter’s algorithm by triangle extremal depth.

Rules:
1. Non-adjacent faces: sort by the **farthest** vertex depth (max dot with camera) (back-to-front).
2. Adjacent faces (sharing an edge): compute signed distance of each triangle’s unique vertex to the other triangle’s plane (using that triangle’s normal). The triangle whose unique vertex has the smaller signed distance is drawn first.
3. Orient normals by inner shell, color yellow if normal·camera ≥0, else purple.

Usage: python generate_tikz_shell.py → shell.tex
"""
import numpy as np
from functools import cmp_to_key

# Output and scale
output_filename = 'shell.tex'
scale = 10.0

# Sampling parameters
usamples, vsamples = 20, 10
ustart, uend = 10.0, 51.0
vstart, vend = 0.0, 2 * np.pi

# Camera angles & vector
az_deg, el_deg = 130, 15
az, el = np.deg2rad(az_deg), np.deg2rad(el_deg)
camera = np.array([np.sin(az)*np.cos(el), -np.cos(az)*np.cos(el), np.sin(el)])

# Shell definitions
def shell_point(u, v):
    u1 = u/100
    return np.array([
        0.05*(1-u1)*(3+np.cos(v))*np.cos(4*np.pi*u1),
        0.05*(1-u1)*(3+np.cos(v))*np.sin(4*np.pi*u1),
        -0.05*(3*u1 + (1-u1)*np.sin(v))
    ])

def innershell_point(u):
    u1 = u/100
    return np.array([0.05*(1-u1)*3*np.cos(4*np.pi*u1),
                     0.05*(1-u1)*3*np.sin(4*np.pi*u1),
                     -0.05*3*u1])

# Build triangles
t = []
us = np.linspace(ustart, uend, usamples+1)
vs = np.linspace(vstart, vend, vsamples+1)
for i in range(usamples):
    for j in range(vsamples):
        u, v = us[i], vs[j]
        du, dv = us[1]-us[0], vs[1]-vs[0]
        A = shell_point(u, v)
        B = shell_point(u+du, v)
        C = shell_point(u, v+dv)
        D = shell_point(u+du, v+dv)
        t.append({'verts': np.array([A, C, D]), 'u_mid': u + du/3})
        t.append({'verts': np.array([A, B, D]), 'u_mid': u + 2*du/3})

# Helpers
def centroid(tri): return np.mean(tri['verts'], axis=0)
def max_depth(tri): return max(np.dot(v, camera) for v in tri['verts'])
def share_two(a, b): return sum(np.allclose(v1, v2) for v1 in a['verts'] for v2 in b['verts']) >= 2

# Compute and orient normals, assign color
for tri in t:
    a, b, c = tri['verts']
    n = np.cross(b-a, c-a)
    # orient outward vs inner shell
    if np.dot(n, centroid(tri) - innershell_point(tri['u_mid'])) < 0:
        n = -n
    tri['normal'] = n
    tri['view_dp'] = np.dot(n, camera)
    tri['color'] = 'yellow' if tri['view_dp'] >= 0 else 'purple!80'

# Adjacency plane-distance function

# def plane_distance(tri_plane, point):
#     p0, p1, p2 = tri_plane['verts']
#     n = tri_plane['normal']
#     # signed distance from point to plane along normal
#     return -np.dot(n, point - p0) / np.linalg.norm(n)

def plane_distance(tri_plane, point):
    p0, p1, p2 = tri_plane['verts']
    n = tri_plane['normal']
    sign = np.sign(np.dot(n, camera))
    return sign * np.dot(n, point - p0) / np.linalg.norm(n)


# Triangle comparator mixing farthest-depth and adjacency rule

def tri_cmp(t1, t2):
    # if adjacent, use plane-distance of unique vertices
    if share_two(t1, t2):
        shared = [v1 for v1 in t1['verts'] for v2 in t2['verts'] if np.allclose(v1, v2)]
        uniq1 = next(v for v in t1['verts'] if not any(np.allclose(v, s) for s in shared))
        uniq2 = next(v for v in t2['verts'] if not any(np.allclose(v, s) for s in shared))
        d1 = plane_distance(t2, uniq1)
        d2 = plane_distance(t1, uniq2)
        # smaller distance (more behind) drawn first
        return -1 if d1 < d2 else 1
    # non-adjacent: sort by farthest vertex depth (back-to-front)
    return -1 if max_depth(t1) < max_depth(t2) else 1

# Sort triangles
from functools import cmp_to_key
t.sort(key=cmp_to_key(tri_cmp))

# Emit standalone TeX
with open(output_filename, 'w') as f:
    f.write(rf"""
% arara: pdflatex
\documentclass[tikz,border=3.14mm]{{standalone}}
\usepackage{{tikz-3dplot}}
\tdplotsetmaincoords{{90-{el_deg}}}{{{az_deg}}}
\begin{{document}}
  \begin{{tikzpicture}}[tdplot_main_coords, scale={scale}]
"""
)
    for tri in t:
        a, b, c = tri['verts'] * scale
        f.write(f"    \\filldraw[fill={tri['color']},draw=black] ({a[0]:.5f},{a[1]:.5f},{a[2]:.5f}) -- "
                f"({b[0]:.5f},{b[1]:.5f},{b[2]:.5f}) -- ({c[0]:.5f},{c[1]:.5f},{c[2]:.5f}) -- cycle;\n")
    f.write(r"""
  \end{tikzpicture}
\end{document}
"""
)
print(f"Wrote {output_filename}")
