# https://tex.stackexchange.com/a/736173/319072
import numpy as np
import sys, os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from Animatetex import animatetex
iterations = 24
def main():
    """
    Purpose:
        Makes an animation of a circling charge, about another.
    Parameters:
        No parameters.
    Return:
        Void.
    """
    animatetex.before_loop()
    for angle in np.linspace(0,40,iterations):
      with open(
          r"Python Scripts\spherical_inversion\preamble.tex", "r"
      ) as preamble:
          preamble = preamble.read()
      with open(
          r"Python Scripts\spherical_inversion\document.tex", "r"
      ) as document:
          document = document.read()
      with open(animatetex.TeX_file, 'w') as latex:
          latex.write(preamble)
          latex.write(r'\pgfmathsetmacro{\rotation}{' + f'{angle}' + '}')
          latex.write(document)
      animatetex.during_loop()
    animatetex.after_loop()
if __name__ == "__main__":
    main()