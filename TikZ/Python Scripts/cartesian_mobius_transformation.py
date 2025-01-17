import numpy as np
import Modules.animatetex as animatetex

numiter = 24

start= r'''
\documentclass{beamer}
\beamertemplatenavigationsymbolsempty

\usepackage{tikz}
\usepackage{tikz-3dplot}

\newcommand{\SP}[2]{%
% #1  - the x or y value of a point on the sphere
% #2  - the z value of that point
#1/(1-#2)}


\newcommand{\ISPX}[2]{%
% Purpose: Given a point on the plane, gives the 'x' coordinate of its 
% inverse stereographic projection.
% Parameters:
% #1  - the x value
% #2  - the y value
2*(#1)/(1+(#1)^2+(#2)^2)%
}

\newcommand{\ISPY}[2]{%
% Purpose: Given a point on the plane, gives the 'y' coordinate of its 
% inverse stereographic projection.
% Parameters:
% #1  - the x value
% #2  - the y value
2*(#2)/(1+(#1)^2+(#2)^2)%
}

\newcommand{\ISPZ}[2]{%
% Purpose: Given a point on the plane, gives the 'z' coordinate of its 
% inverse stereographic projection.
% Parameters:
% #1  - the x value
% #2  - the y value
(-1+(#1)^2+(#2)^2)/(1+(#1)^2+(#2)^2)%
}

\pgfmathsetmacro\elevation{30}
\pgfmathsetmacro\azimuth{45}

\pgfmathsetmacro{\CameraX}{sin(\azimuth)*cos(\elevation)}
\pgfmathsetmacro{\CameraY}{-cos(\azimuth)*cos(\elevation)}
\pgfmathsetmacro{\CameraZ}{sin(\elevation)}
'''

end = r'''
\begin{document}
    \begin{frame}
        \centering
        \tdplotsetmaincoords{90-\elevation}{\azimuth}
        \begin{tikzpicture}[tdplot_main_coords,scale=0.97]
            \path[white,tdplot_screen_coords] 
            (-\textwidth/2,-\textheight/2) rectangle 
            (\textwidth/2,\textheight/2);
            \clip[tdplot_screen_coords] 
            (-\textwidth/2,-\textheight/2) rectangle 
            (\textwidth/2,\textheight/2);
            \tdplotsetrotatedcoords{\rotation}{\rotation}{\rotation}
            \pgfmathsetmacro{\samples}{36}
            \foreach[parse=true, evaluate=\x] \x in {-5,-5+(5-(-5))/\samples,...,5} {
                \pgfmathsetmacro{\samples}{300}
                \foreach[parse=true, evaluate=\y,count=\c from 0] \y in {-5,-5+(5-(-5))/\samples,...,5} {
                    \tdplottransformrotmain
                        {\ISPX{\x}{\y}}
                        {\ISPY{\x}{\y}}
                        {\ISPZ{\x}{\y}}
                        \pgfmathsetmacro{\startx}{\tdplotresx}
                        \pgfmathsetmacro{\starty}{\tdplotresy}
                        \pgfmathsetmacro{\startz}{\tdplotresz}
                    \tdplottransformrotmain
                        {\ISPX{\x}{\y+(5-(-5))/\samples}}
                        {\ISPY{\x}{\y+(5-(-5))/\samples}}
                        {\ISPZ{\x}{\y+(5-(-5))/\samples}}
                        \pgfmathsetmacro{\endx}{\tdplotresx}
                        \pgfmathsetmacro{\endy}{\tdplotresy}
                        \pgfmathsetmacro{\endz}{\tdplotresz}
                    \pgfmathparse{\c!=\samples && \endz<0.999}
                    \ifnum\pgfmathresult=1
                        \draw[ultra thin] 
                        ({\SP{\startx}{\startz}},{\SP{\starty}{\startz}},0) -- 
                        ({\SP{\endx}{\endz}},{\SP{\endy}{\endz}},0);
                    \fi
                }
            }
            \pgfmathsetmacro{\samples}{36}
            \foreach[parse=true, evaluate=\y] \y in {-5,-5+(5-(-5))/\samples,...,5} {
                \pgfmathsetmacro{\samples}{300}
                \foreach[parse=true, evaluate=\x,count=\c from 0] \x in {-5,-5+(5-(-5))/\samples,...,5} {
                    \tdplottransformrotmain
                        {\ISPX{\x}{\y}}
                        {\ISPY{\x}{\y}}
                        {\ISPZ{\x}{\y}}
                        \pgfmathsetmacro{\startx}{\tdplotresx}
                        \pgfmathsetmacro{\starty}{\tdplotresy}
                        \pgfmathsetmacro{\startz}{\tdplotresz}
                    \tdplottransformrotmain
                        {\ISPX{\x+(5-(-5))/\samples}{\y}}
                        {\ISPY{\x+(5-(-5))/\samples}{\y}}
                        {\ISPZ{\x+(5-(-5))/\samples}{\y}}
                        \pgfmathsetmacro{\endx}{\tdplotresx}
                        \pgfmathsetmacro{\endy}{\tdplotresy}
                        \pgfmathsetmacro{\endz}{\tdplotresz}
                    \pgfmathparse{\c!=\samples && \endz<0.999}
                    \ifnum\pgfmathresult=1
                        \draw[ultra thin] 
                        ({\SP{\startx}{\startz}},{\SP{\starty}{\startz}},0) -- 
                        ({\SP{\endx}{\endz}},{\SP{\endy}{\endz}},0);
                    \fi
                }
            }
            \fill[white] ({cos(\azimuth)},{sin(\azimuth)}) arc [start angle=\azimuth, end angle={\azimuth-180}, radius=1] -- cycle;
            \fill[tdplot_screen_coords,white] ({cos(0)},{sin(0)}) arc [start angle=0, end angle=180, radius=1] -- cycle;
            \pgfmathsetmacro{\samples}{36}
            \foreach[parse=true, evaluate=\x] \x in {-5,-5+(5-(-5))/\samples,...,5} {
                \pgfmathsetmacro{\samples}{300}
                \foreach[parse=true, evaluate=\y,count=\c from 0] \y in {-5,-5+(5-(-5))/\samples,...,5} {
                    \tdplottransformrotmain
                        {\ISPX{\x}{\y}}
                        {\ISPY{\x}{\y}}
                        {\ISPZ{\x}{\y}}
                        \pgfmathsetmacro{\startx}{\tdplotresx}
                        \pgfmathsetmacro{\starty}{\tdplotresy}
                        \pgfmathsetmacro{\startz}{\tdplotresz}
                    \tdplottransformrotmain
                        {\ISPX{\x}{\y+(5-(-5))/\samples}}
                        {\ISPY{\x}{\y+(5-(-5))/\samples}}
                        {\ISPZ{\x}{\y+(5-(-5))/\samples}}
                        \pgfmathsetmacro{\endx}{\tdplotresx}
                        \pgfmathsetmacro{\endy}{\tdplotresy}
                        \pgfmathsetmacro{\endz}{\tdplotresz}
                    \pgfmathsetmacro\dotproduct{(\CameraX)*(\endx) + (\CameraY)*(\endy) + (\CameraZ)*(\endz)}
                    \pgfmathparse{\dotproduct>0 && \endz>0 && \c!=\samples}
                    \ifnum\pgfmathresult=1
                        \draw[ultra thin] 
                        (\startx,\starty,\startz) --
                        (\endx,\endy,\endz);
                    \fi
                }
            }
            \pgfmathsetmacro{\samples}{36}
            \foreach[parse=true, evaluate=\y] \y in {-5,-5+(5-(-5))/\samples,...,5} {
                \pgfmathsetmacro{\samples}{300}
                \foreach[parse=true, evaluate=\x,count=\c from 0] \x in {-5,-5+(5-(-5))/\samples,...,5} {
                    \tdplottransformrotmain
                        {\ISPX{\x}{\y}}
                        {\ISPY{\x}{\y}}
                        {\ISPZ{\x}{\y}}
                        \pgfmathsetmacro{\startx}{\tdplotresx}
                        \pgfmathsetmacro{\starty}{\tdplotresy}
                        \pgfmathsetmacro{\startz}{\tdplotresz}
                    \tdplottransformrotmain
                        {\ISPX{\x+(5-(-5))/\samples}{\y}}
                        {\ISPY{\x+(5-(-5))/\samples}{\y}}
                        {\ISPZ{\x+(5-(-5))/\samples}{\y}}
                        \pgfmathsetmacro{\endx}{\tdplotresx}
                        \pgfmathsetmacro{\endy}{\tdplotresy}
                        \pgfmathsetmacro{\endz}{\tdplotresz}
                    \pgfmathsetmacro\dotproduct{(\CameraX)*(\endx) + (\CameraY)*(\endy) + (\CameraZ)*(\endz)}
                    \pgfmathparse{\dotproduct>0 && \endz>0 && \c!=\samples}
                    \ifnum\pgfmathresult=1
                        \draw[ultra thin] 
                        (\startx,\starty,\startz) --
                        (\endx,\endy,\endz);
                    \fi
                }
            }
        \end{tikzpicture}
    \end{frame}
\end{document}
'''

def main():
  """
    Purpose:
        Makes an animation of a Mobius Transformation.
    Parameters:
        No parameters.
    Return:
        Void.
    """
  animatetex.before_loop()
  for angle in np.linspace(0,40,numiter):
      with open(animatetex.TeX_file, 'w') as f:
          f.write(start)
          f.write(r'\pgfmathsetmacro{\rotation}{' +f'{angle}' +'}\n')
          f.write(end)
      animatetex.during_loop()
  animatetex.after_loop()

if __name__ == "__main__":
    main()