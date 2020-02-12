## Curve handle balancer and harmonizer for Windows FontLab 5.2
## Requirements
These macros have no dependencies outside of the standard library. The `balancer_core` extension module is written in Cython and in Python 3 syntax where it is natively supported by Cython.

### Optional
* cython
**pip install cython**
<https://github.com/cython/cython>

* Windows GCC (MinGW) 4.3.3
<https://github.com/develersrl/gccwinbinaries>

### Installation
Download the latest release and unzip. Move the files to your FontLab Macros folder.

```
[user folder]
`-- Documents
    `-- Fontlab
        `-- Studio 5
            `-- Macros
                |-- balancer
                |   `-- balancer.py
                |-- harmonizer
                |   `-- harmonizer.py
                `-- System
                    `-- Modules
                        `--balancer_core.pyd
```

### Functionality
The `balance_curves()` and `harmonize_curves()` functions from the `balancer_core` module are the core functions. The `balancer.py` and `harmonize.py` macros will run with the glyph window open. If any curve segments are selected (highlighted), only those curve segements which are selected will be balanced and/or harmonized. These two macros can be assigned to keyboard shortcuts for quick access.

Although these macros are intended to run within the glyph window, the `balance_curves()` and `harmonize_curves()` functions from the `balancer_core` accept a single FontLab glyph object as their sole arguments. This means that if a user wished, they could create their own scripts to balance and/or harmonize any list of glyphs. Using the functions in this way can make changes to the outlines which may or may not be what you would expect. These functions are agnostic and just because they change an outline a certain way, it does not mean its changes are correct.

### Example
```
-------------------------------------------------------------------------------
EXAMPLE HARMONIZATION SCRIPT
-------------------------------------------------------------------------------
# coding: utf-8

from FL import fl

from balancer_core import harmonize_curves

glyphs = [glyph for glyph in fl.font.glyphs if glyph.name.startswith('a')]
for glyph in glyphs:
	harmonize_curves(glyph)

-------------------------------------------------------------------------------
```

#### Credits
The method for `balance_curves()` is based on Jens Kutilek's Curve-Eq for RoboFont.

[Curve Equalizer](https://github.com/jenskutilek/Curve-Equalizer)

Portions of the `harmonize_curves()` are based on Simon Cozens' harmonization gist.

[https://gist.github.com/simoncozens (harmonization.md)](https://gist.github.com/simoncozens/3c5d304ae2c14894393c6284df91be5b)

#### Author
Jameson R Spires

#### License
This macro is available under the [MIT License](https://opensource.org/licenses/MIT).

#### Version history
* version 0.1.0
initial release
