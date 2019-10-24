# pysmurf

[![Documentation Status](https://readthedocs.org/projects/pysmurf/badge/?version=latest)](https://pysmurf.readthedocs.io/en/latest/?badge=latest)

The python control software for SMuRF. Includes scripts to do low level
commands as well as higher level analysis.

## Installation
To install pysmurf clone this repository and install using pip:

```
git clone https://github.com/slaclab/pysmurf.git
cd pysmurf/
pip3 install -r requirements.txt
pip3 install .
```

## Documentation
Documentation is built using Sphinx, and follows the
[Google Style Docstrings][1]. To build the documentation first install the
pysmurf package, then run:

```
cd docs/
make html
```

Output will be located in `_build/html`. You can view the compiled
documentation by opening `_build/html/index.html` in the browser of your
choice.

[1]: https://sphinxcontrib-napoleon.readthedocs.io/en/latest/example_google.html
