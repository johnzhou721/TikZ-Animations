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
  for angle in np.linspace(0,360,iterations):
      with open(animatetex.TeX_file, 'w') as latex:
          latex.write(
              '\\documentclass[border=3.14mm]{standalone}\n' +
              '\\usepackage{Sources/temp_pline_animation/preamble}\n' +
              r'\pgfmathsetmacro{\t}{' + f'{angle}' + '}\n' +
              '\\input{Sources/temp_pline_animation/document}\n'
          )
      animatetex.during_loop()
  animatetex.after_loop()
if __name__ == "__main__":
    main()