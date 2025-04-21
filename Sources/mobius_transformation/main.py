import numpy as np
import sys, os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from Animatetex import animatetex
iterations = 24
def main():
  """
    This code animates a Mobius transformation.
    In other words, an inversion of the Cartesian grid.
  """
  animatetex.before_loop()
  for angle in np.linspace(0,40,iterations):
      with open(animatetex.TeX_file, 'w') as latex:
          latex.write(
              '\\documentclass{beamer}\n' +
              '\\beamertemplatenavigationsymbolsempty\n'
              '\\usepackage{Sources/mobius_transformation/preamble}\n' +
              '\\directlua{rotation = ' + f'{angle}' + '}\n' +
              '\\begin{document}\n' +
              '\\input{Sources/mobius_transformation/document}\n' +
              '\\end{document}'
          )
      animatetex.during_loop()
  animatetex.after_loop()
if __name__ == "__main__":
    main()