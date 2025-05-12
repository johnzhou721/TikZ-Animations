import numpy as np
import sys, os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from Animatetex import animatetex
iterations = 24
def main():
  """
    This code animates a spinning bumpy sphere.
  """
  animatetex.before_loop()
  for angle in np.linspace(-10,350,iterations):
      with open(animatetex.TeX_file, 'w') as latex:
          latex.write(
              '\\documentclass{beamer}\n' +
              '\\beamertemplatenavigationsymbolsempty\n'
              '\\usepackage{Sources/new_pline-vec_animation/preamble}\n' +
              r'\pgfmathsetmacro{\t}{' + f'{angle}' + '}\n' +
              '\\begin{document}\n' +
              '\\input{Sources/new_pline-vec_animation/document}\n' +
              '\\end{document}'
          )
      animatetex.during_loop()
  animatetex.after_loop()
if __name__ == "__main__":
    main()