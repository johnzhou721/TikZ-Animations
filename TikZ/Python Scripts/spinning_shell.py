import numpy as np
import Modules.animatetex as animatetex

numiter = 24

preamble= r'''
\documentclass{beamer}
\beamertemplatenavigationsymbolsempty

\usepackage{
    tikz
    ,tikz-3dplot
    ,TikZ/packages/tikz_sorting
}

\pgfmathdeclarefunction{shellX}{2}{%
  \pgfmathparse{0.02*(1-#1)*(3+cos(#2))*cos(4*pi*#1)}%
}
\pgfmathdeclarefunction{shellY}{2}{%
  \pgfmathparse{0.02*(1-#1)*(3+cos(#2))*sin(4*pi*#1)}%
}
\pgfmathdeclarefunction{shellZ}{2}{%
  \pgfmathparse{-0.02*(3*#1+(1-#1)*sin(#2))+1.5}%
}

\pgfmathdeclarefunction{innershellX}{1}{%
  \pgfmathparse{0.02*(1-#1)*3*cos(4*pi*#1)}%
}
\pgfmathdeclarefunction{innershellY}{1}{%
  \pgfmathparse{0.02*(1-#1)*3*sin(4*pi*#1)}%
}
\pgfmathdeclarefunction{innershellZ}{1}{%
  \pgfmathparse{-0.02*(3*#1)+1.5}%
}
'''

postscript = r'''
\pgfmathsetmacro{\azimuth}{280+\azimuthchange}
\pgfmathsetmacro{\elevation}{15}
% https://tex.stackexchange.com/a/729510/319072
\pgfmathsetmacro{\CameraX}{sin(\azimuth)*cos(\elevation)}
\pgfmathsetmacro{\CameraY}{-cos(\azimuth)*cos(\elevation)}
\pgfmathsetmacro{\CameraZ}{sin(\elevation)}

\begin{document}

    \NewSegmentList{shell}
    \tdplotsetmaincoords{90-\elevation}{\azimuth}
    \begin{tikzpicture}[tdplot_main_coords,scale=0.97]
        \path[tdplot_screen_coords] (-\textwidth/2,-\textheight/2) rectangle (\textwidth/2,\textheight/2);
        \clip[tdplot_screen_coords] (-\textwidth/2,-\textheight/2) rectangle (\textwidth/2,\textheight/2);
        
        
        \pgfmathsetmacro\usamples{20}
        \pgfmathsetmacro\vsamples{10}
        \pgfmathsetmacro\ustart{10}
        \pgfmathsetmacro\uend{51}
        \pgfmathsetmacro\usamplediff{(\uend-\ustart)/\usamples}
        \pgfmathsetmacro\vstart{0}
        \pgfmathsetmacro\vend{360}
        \pgfmathsetmacro\vsamplediff{(\vend-\vstart)/\vsamples}
        \foreach[parse=true, evaluate=\u] \u in {\ustart,\ustart+\usamplediff,...,\uend-\usamplediff} {
            \foreach[parse=true, evaluate=\v] \v in {\vstart,\vstart+\vsamplediff,...,\vend-\vsamplediff} {

                % first point
                \pgfmathsetmacro\ax{shellX(\u,\v)}
                \pgfmathsetmacro\ay{shellY(\u,\v)}
                \pgfmathsetmacro\az{shellZ(\u,\v)}

                % second point
                \pgfmathsetmacro\bx{shellX(\u+\usamplediff,\v)}
                \pgfmathsetmacro\by{shellY(\u+\usamplediff,\v)}
                \pgfmathsetmacro\bz{shellZ(\u+\usamplediff,\v)}

                % third point
                \pgfmathsetmacro\cx{shellX(\u,\v+\vsamplediff)}
                \pgfmathsetmacro\cy{shellY(\u,\v+\vsamplediff)}
                \pgfmathsetmacro\cz{shellZ(\u,\v+\vsamplediff)}

                % fourth point
                \pgfmathsetmacro\dx{shellX(\u+\usamplediff,\v+\vsamplediff)}
                \pgfmathsetmacro\dy{shellY(\u+\usamplediff,\v+\vsamplediff)}
                \pgfmathsetmacro\dz{shellZ(\u+\usamplediff,\v+\vsamplediff)}

                % average 1
                \pgfmathsetmacro\avgonex{(\ax+\cx+\dx)/3}
                \pgfmathsetmacro\avgoney{(\ay+\cy+\dy)/3}
                \pgfmathsetmacro\avgonez{(\az+\cz+\dz)/3}

                \pgfmathsetmacro\avgonex{\avgonex/50}
                \pgfmathsetmacro\avgoney{\avgoney/50}
                \pgfmathsetmacro\avgonez{\avgonez/50}

                % average 2
                \pgfmathsetmacro\avgtwox{(\ax+\bx+\dx)/3}
                \pgfmathsetmacro\avgtwoy{(\ay+\by+\dy)/3}
                \pgfmathsetmacro\avgtwoz{(\az+\bz+\dz)/3}

                \pgfmathsetmacro\avgtwox{\avgtwox/50}
                \pgfmathsetmacro\avgtwoy{\avgtwoy/50}
                \pgfmathsetmacro\avgtwoz{\avgtwoz/50}

                % depth dot products w.r.t camera vector
                \pgfmathsetmacro\depthDPone{
                    \CameraX*\avgonex + 
                    \CameraY*\avgoney + 
                    \CameraZ*\avgonez
                }

                \pgfmathsetmacro\depthDPtwo{
                    \CameraX*\avgtwox + 
                    \CameraY*\avgtwoy + 
                    \CameraZ*\avgtwoz
                }

                % spanning vectors
                \pgfmathsetmacro\cax{\cx-\ax}
                \pgfmathsetmacro\cay{\cy-\ay}
                \pgfmathsetmacro\caz{\cz-\az}

                \pgfmathsetmacro\dax{\dx-\ax}
                \pgfmathsetmacro\day{\dy-\ay}
                \pgfmathsetmacro\daz{\dz-\az}

                \pgfmathsetmacro\bax{\bx-\ax}
                \pgfmathsetmacro\bay{\by-\ay}
                \pgfmathsetmacro\baz{\bz-\az}

                % average 1
                \pgfmathsetmacro\avgonex{(\ax+\cx+\dx)/3}
                \pgfmathsetmacro\avgoney{(\ay+\cy+\dy)/3}
                \pgfmathsetmacro\avgonez{(\az+\cz+\dz)/3}

                % average 2
                \pgfmathsetmacro\avgtwox{(\ax+\bx+\dx)/3}
                \pgfmathsetmacro\avgtwoy{(\ay+\by+\dy)/3}
                \pgfmathsetmacro\avgtwoz{(\az+\bz+\dz)/3}

                % normal vectors
                \tdplotcrossprod(\cax,\cay,\caz)(\dax,\day,\daz)
                \pgfmathsetmacro\aviewingDP{
                    \tdplotresx*(\avgonex-innershellX(\u+\usamplediff/2)) + 
                    \tdplotresy*(\avgoney-innershellY(\u+\usamplediff/2)) + 
                    \tdplotresz*(\avgonez-innershellZ(\u+\usamplediff/2))
                }
                \pgfmathparse{\aviewingDP<0}
                \ifnum\pgfmathresult=1
                    \tdplotcrossprod(\dax,\day,\daz)(\cax,\cay,\caz)
                \fi
                \pgfmathsetmacro\afinalDP{
                    \CameraX*\tdplotresx +
                    \CameraY*\tdplotresy +
                    \CameraZ*\tdplotresz
                }

                \tdplotcrossprod(\bax,\bay,\baz)(\dax,\day,\daz)
                \pgfmathsetmacro\bviewingDP{
                    \tdplotresx*(\avgtwox-innershellX(\u+\usamplediff/2)) + 
                    \tdplotresy*(\avgtwoy-innershellY(\u+\usamplediff/2)) + 
                    \tdplotresz*(\avgtwoz-innershellZ(\u+\usamplediff/2))
                }
                \pgfmathparse{\bviewingDP<0}
                \ifnum\pgfmathresult=1
                    \tdplotcrossprod(\dax,\day,\daz)(\bax,\bay,\baz)
                \fi
                \pgfmathsetmacro\bfinalDP{
                    \CameraX*\tdplotresx +
                    \CameraY*\tdplotresy +
                    \CameraZ*\tdplotresz
                }

                % add segments to list
                \ExpandArgs{nne}\AddSegment{shell}
                {\depthDPone}
                {%
                    \def\noexpand\dotproduct{\afinalDP}%
                    \def\noexpand\aax{\ax}%
                    \def\noexpand\aay{\ay}%
                    \def\noexpand\aaz{\az}%
                    \def\noexpand\bbx{\cx}%
                    \def\noexpand\bby{\cy}%
                    \def\noexpand\bbz{\cz}%
                    \def\noexpand\ccx{\dx}%
                    \def\noexpand\ccy{\dy}%
                    \def\noexpand\ccz{\dz}%
                }%
                
                \ExpandArgs{nne}\AddSegment{shell}
                {\depthDPtwo}
                {%
                    \def\noexpand\dotproduct{\bfinalDP}%
                    \def\noexpand\aax{\ax}%
                    \def\noexpand\aay{\ay}%
                    \def\noexpand\aaz{\az}%
                    \def\noexpand\bbx{\bx}%
                    \def\noexpand\bby{\by}%
                    \def\noexpand\bbz{\bz}%
                    \def\noexpand\ccx{\dx}%
                    \def\noexpand\ccy{\dy}%
                    \def\noexpand\ccz{\dz}%
                }%
            }
        }

            \SortSegmentList{shell}
            \LoopOverSegmentList{shell}
                {   
                \pgfmathparse{\dotproduct>=0}
                    \ifnum\pgfmathresult=1
                        \tikzset{myfill/.style =  yellow}
                    \else
                        \tikzset{myfill/.style =  purple!80}
                    \fi
                  \fill[myfill,postaction={draw,black,ultra thin}] 
                  (\aax,\aay,\aaz) -- (\bbx,\bby,\bbz) -- (\ccx,\ccy,\ccz) --cycle;
                  \pgfmathparse{\dotproduct>=0}
                  \ifnum\pgfmathresult=1
                  %\draw[->](\centroidx,\centroidy,\centroidz) -- ++($0.5*(\normalx cm,\normaly cm,\normalz cm)$);
                  \fi
                }
    \end{tikzpicture}
\end{document}
'''

def main():
    """
    Purpose:
        This function animates a spinning bumpy sphere.
    Parameters:
        No parameters.
    Return:
        Void.
    """
    animatetex.before_loop()
    for theta in np.linspace(-15,15,numiter//2):
        with open(animatetex.TeX_file, 'w') as TeX:
            TeX.write(preamble)
            TeX.write(r'\pgfmathsetmacro{\azimuthchange}{' +f'{theta}' +'}')
            TeX.write(postscript)
        animatetex.during_loop()
    for theta in np.linspace(15,-15,numiter//2):
        with open(animatetex.TeX_file, 'w') as TeX:
            TeX.write(preamble)
            TeX.write(r'\pgfmathsetmacro{\azimuthchange}{' +f'{theta}' +'}')
            TeX.write(postscript)
        animatetex.during_loop()
    animatetex.after_loop()

if __name__ == "__main__":
    main()