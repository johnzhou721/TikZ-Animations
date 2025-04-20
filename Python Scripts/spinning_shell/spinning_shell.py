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
    with open(
        r"Python Scripts\spinning_shell\preamble.tex", "r"
    ) as preamble:
        preamble = preamble.read()
    with open(
        r"Python Scripts\spinning_shell\document.tex", "r"
    ) as document:
        document = document.read()
    animatetex.before_loop()
    for angle in np.linspace(-15,15,iterations//2):
        with open(animatetex.TeX_file, 'w') as latex:
            latex.write(preamble)
            latex.write(r'\pgfmathsetmacro{\azimuthchange}{' + f'{angle}' + '}')
            latex.write(document)
        animatetex.during_loop()
    for angle in np.linspace(15,-15,iterations//2):
        with open(animatetex.TeX_file, 'w') as latex:
            latex.write(preamble)
            latex.write(r'\pgfmathsetmacro{\azimuthchange}{' + f'{angle}' + '}')
            latex.write(document)
        animatetex.during_loop()
    animatetex.after_loop()
if __name__ == "__main__":
    main()