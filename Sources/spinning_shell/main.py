# https://tex.stackexchange.com/a/736173/319072
import numpy as np
import sys, os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from Animatetex import animatetex
iterations = 24
def main():
    """
    Purpose:
        Makes an animation of a palindroming triangulated parametric
        surface.
    Parameters:
        No parameters.
    Return:
        Void.
    """
    animatetex.before_loop()
    for angle in np.linspace(-15,15,iterations//2):
        with open(animatetex.TeX_file, 'w') as latex:
            latex.write(
              '\\documentclass{beamer}\n' +
              '\\beamertemplatenavigationsymbolsempty\n'
              '\\usepackage{Sources/spinning_shell/preamble}\n' +
              r'\pgfmathsetmacro{\azimuthchange}{' + f'{angle}' + '}\n' +
              '\\begin{document}\n' +
              '\\input{Sources/spinning_shell/document}\n' +
              '\\end{document}'
          )
        animatetex.during_loop()
    for angle in np.linspace(15,-15,iterations//2):
        with open(animatetex.TeX_file, 'w') as latex:
            latex.write(
              '\\documentclass{beamer}\n' +
              '\\beamertemplatenavigationsymbolsempty\n'
              '\\usepackage{Sources/spinning_shell/preamble}\n' +
              r'\pgfmathsetmacro{\azimuthchange}{' + f'{angle}' + '}\n' +
              '\\begin{document}\n' +
              '\\input{Sources/spinning_shell/document}\n' +
              '\\end{document}'
          )
        animatetex.during_loop()
    animatetex.after_loop()
if __name__ == "__main__":
    main()