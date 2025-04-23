import numpy as np
import sys, os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from Animatetex import animatetex
iterations = 24
def main():
  """
  """
  animatetex.before_loop()
  for angle in np.linspace(0,10,iterations):
      with open(animatetex.TeX_file, 'w') as latex:
          latex.write(
              '\\documentclass{beamer}\n' +
              '\\beamertemplatenavigationsymbolsempty\n'
              '\\usepackage{Sources/elliptic_spherical_mobius_transformation/preamble}\n' +
              '\\directlua{rotation = ' + f'{angle}' + '}\n' +
              '\\begin{document}\n' +
              '\\input{Sources/elliptic_spherical_mobius_transformation/document}\n' +
              '\\end{document}'
          )
      animatetex.during_loop()
  animatetex.after_loop()
if __name__ == "__main__":
    main()