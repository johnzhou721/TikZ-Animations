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
  count = 0
  for angle in np.linspace(0,360,iterations+1):
      count += 1
      if count < 360:
        with open(animatetex.TeX_file, 'w') as latex:
            latex.write(
                '\\documentclass{beamer}\n' +
                '\\beamertemplatenavigationsymbolsempty\n'
                '\\usepackage{Sources/spinning_shell/preamble}\n' +
                '\\directlua{rotation = ' + f'{angle}' + '}\n' +
                '\\begin{document}\n' +
                '\\input{Sources/spinning_shell/document}\n' +
                '\\end{document}'
            )
        animatetex.during_loop()
  animatetex.after_loop()
if __name__ == "__main__":
    main()