# https://tex.stackexchange.com/a/736173/319072
import numpy as np
import sys, os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from Animatetex import animatetex
iterations = 24
def main():
    """
    Purpose:
        This animates the stereographic projection of a revolving
        mesh sphere.
    Parameters:
        No parameters.
    Return:
        Void.
    """
    animatetex.before_loop()
    for angle in np.linspace(0,40,iterations):
      with open(animatetex.TeX_file, 'w') as latex:
          latex.write(
              '\\documentclass{beamer}\n' +
              '\\beamertemplatenavigationsymbolsempty\n'
              '\\usepackage{Sources/spherical_inversion/preamble}\n' +
              r'\pgfmathsetmacro{\rotation}{' + f'{angle}' + '}\n' +
              '\\begin{document}\n' +
              '\\input{Sources/spherical_inversion/document}\n' +
              '\\end{document}'
          )
      animatetex.during_loop()
    animatetex.after_loop()
if __name__ == "__main__":
    main()