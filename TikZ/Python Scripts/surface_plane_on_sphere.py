import numpy as np
from Modules import animatetex

# Credit for formulae: https://www.researchgate.net/publication/376028984_Visualizing_atomic_orbitals_of_an_electron_by_Latex

numiter = 24

preamble= r'''
\documentclass{beamer}
\beamertemplatenavigationsymbolsempty
\usepackage{tikz}
\usepackage{tikz-3dplot}
'''

postscript = r'''
\begin{document}
\pgfmathsetmacro{\azimuth}{280+\Vt*20}
\pgfmathsetmacro{\elevation}{30}
% https://tex.stackexchange.com/a/729510/319072
\pgfmathsetmacro{\CameraX}{sin(\azimuth)*cos(\elevation)}
\pgfmathsetmacro{\CameraY}{-cos(\azimuth)*cos(\elevation)}
\pgfmathsetmacro{\CameraZ}{sin(\elevation)}
\newcommand{\loxodromeX}[1]{
    cos(#1)/sqrt((cos(#1))^2+(sin(#1))^2+(#1/360)^2)
}
\newcommand{\loxodromeY}[1]{
    sin(#1)/sqrt((cos(#1))^2+(sin(#1))^2+(#1/360)^2)
}
\newcommand{\loxodromeZ}[1]{
    (#1/360)/(sqrt((cos(#1))^2+(sin(#1))^2+(#1/360)^2))
}

\tdplotsetmaincoords{90-\elevation}{\azimuth}
\begin{tikzpicture}[tdplot_main_coords]

    \path[white,tdplot_screen_coords] 
        (-\textwidth/2,-\textheight/2) rectangle 
        (\textwidth/2,\textheight/2);
        \clip[tdplot_screen_coords] 
        (-\textwidth/2,-\textheight/2) rectangle 
        (\textwidth/2,\textheight/2);

    \makeatletter
    % normal equation
    \@ifdefinable\na{\edef\na{\fpeval{\loxodromeX{\Vt}}}}
    \@ifdefinable\nb{\edef\nb{\fpeval{\loxodromeY{\Vt}}}}
    \@ifdefinable\nc{\edef\nc{\fpeval{\loxodromeZ{\Vt}}}}
    \@ifdefinable\nd{\edef\nd{\fpeval{-1}}}
    \@ifdefinable\nl{\edef\nl{\fpeval{sqrt((\na)^2+(\nb)^2+(\nc)^2)}}}
    % orthogonal projection of point on plane
    \@ifdefinable\pxo{\edef\pxo{\fpeval{0}}}
    \@ifdefinable\pyo{\edef\pyo{\fpeval{0}}}
    \@ifdefinable\pzo{\edef\pzo{\fpeval{0}}}
    \@ifdefinable\pl{
        \edef\pl{
            \fpeval{
                (
                    \na*\pxo+
                    \nb*\pyo+
                    \nc*\pzo-
                    \nd
                )/(
                    (\nl)^2
                )
            }
        }
    }
    \@ifdefinable\px{\edef\px{\fpeval{\pxo-\pl*\na}}}
    \@ifdefinable\py{\edef\py{\fpeval{\pyo-\pl*\nb}}}
    \@ifdefinable\pz{\edef\pz{\fpeval{\pzo-\pl*\nc}}}
    \makeatother

    %\draw[->] (0,0,0) -- (5,0,0);
    %\draw[->] (0,0,0) -- (0,5,0);
    %\draw[->] (0,0,0) -- (0,0,5);

    \newcommand{\myUnitSphere}{
        \foreach \latitude in {-80,-70,...,80} {
            \path[domain=0:360,draw] plot 
                (
                    {cos(\latitude)*cos(\x)}
                    ,{cos(\latitude)*sin(\x)}
                    ,{sin(\latitude)}
                );
        }
        \foreach \longitude in {0,10,...,170} {
            \path[domain=0:360,draw,line join=round] plot 
                (
                    {cos(\x)*cos(\longitude)}
                    ,{cos(\x)*sin(\longitude)}
                    ,{sin(\x)}
                );
        }
    }
    
    \newcommand{\myPlane}{
        \coordinate (Shift) at (\px,\py,\pz);
        \tdplotsetrotatedcoordsorigin{(Shift)}
        \tdplotsetrotatedcoords
          {\fpeval{atand(\nb/\na)}}
          {\fpeval{90-atand(\nc/sqrt((\na)^2+(\nb)^2))}}
          {\fpeval{3.14159+\Vt*20}}
    
        \begin{scope}[tdplot_rotated_coords,canvas is xy plane at z=0]
            \pgflowlevelsynccm
            \path[fill=white!50!black,fill opacity=0.7,draw=black] (-2,-2) -- (2,-2) -- (2,2) -- (-2,2) -- cycle;
            \draw[->] (0,0) -- (1,0);
            \draw[->] (0,0) -- (0,1);
        \end{scope}
        \begin{scope}[tdplot_rotated_coords]
            %\draw[->] (0,0,0) -- (1,0,0);
            %\draw[->] (0,0,0) -- (0,1,0);
            \draw[->] (0,0,0) -- (0,0,1);
            \path (-2,-2) -- (2,-2) -- (2,2) -- (-2,2) -- cycle;
        \end{scope}
    }

    \pgfmathparse{
        \fpeval{
            \CameraX*\na+
            \CameraY*\nb+
            \CameraZ*\nc
        }
        >
        0
    }

    \ifnum\pgfmathresult=1
        \myUnitSphere
        \myPlane
    \else
        \myPlane
        \myUnitSphere
    \fi
\end{tikzpicture}
\end{document}
'''

def main():
    """
    Purpose:
        Makes an animation of four spinning atomic orbitals.
    Parameters:
        No parameters.
    Return:
        Void.
    """
    animatetex.before_loop()
    for angle in np.linspace(-5,5,numiter):
        with open(animatetex.TeX_file, 'w') as f:
            f.write(preamble)
            f.write(r'\newcommand{\Vt}{' +f'{angle}' +'}')
            f.write(postscript)
        animatetex.during_loop()
    animatetex.after_loop()

if __name__ == "__main__":
    main()