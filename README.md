## Curve handle balancer and harmonizer for Windows FontLab 5.2

## Requirements

These macros have no dependencies outside of the standard library. The `balancer_core` extension module is written in Cython and C++.

**Optional**
* cython  
  **pip install cython**  
  <a>https://github.com/cython/cython</a>  

* Windows GCC (MinGW) 4.3.3  
  <a>https://github.com/develersrl/gccwinbinaries</a>  


## Installation

Installation can be accomplished using a FontLab installer (`FLW`) or a `ZIP` archive.
#### FontLab Installer

Download the lastest release FontLab installer (`FLW`) file and drag it into the FontLab main window then restart FontLab or reset macro system.
#### ZIP Archive

Download and extract the latest release `ZIP` file and move the extracted files to your FontLab Macros folder. The default directory structure is shown below.
```
[user folder]
    └── Documents  
        └── Fontlab  
            └── Studio 5  
                └── Macros  
                    ├── balancer  
                    |   └── balancer.py  
                    ├── harmonizer  
                    |   └── harmonizer.py  
                    └── System  
                        └── Modules  
                            └── balancer_core.pyd  
```

**Functionality**

`balance_curves()` and `harmonize_curves()` from the `balancer_core` extension module are the core functions. The `balancer.py` and `harmonize.py` macros will run with the glyph window open. If any curve nodes/segments are selected (highlighted), only those curve nodes/segments which are selected will be balanced and/or harmonized. These two macros can be assigned to keyboard shortcuts for quick access.

The `harmonize_curves()` method only harmonizes curves with handles running exactly vertical or horizontal.

These functions are agnostic and any changes it makes should **not** be construed as *better* in any way. The designer should always trust their eyes when evaluating glyph outlines, since they are the only one who would know how they want the outline to appear. For this reason, it is suggested to run these from the glyph window so any changes can be made on a case-by-case basis.

Although these macros are intended to run within the glyph window, the `balance_curves()` and `harmonize_curves()` functions from the `balancer_core` extension module accept a single FontLab glyph-object as their sole arguments. This means that if a user wished, they could create their own scripts to balance and/or harmonize any list of glyphs. Using the functions in this way can make changes on many glyph outlines which may or may not be what you would expect.

**Example**
```
-------------------------------------------------------------------------------
EXAMPLE HARMONIZATION SCRIPT
-------------------------------------------------------------------------------
# coding: utf-8

from FL import fl

from balancer_core import harmonize_curves

glyphs = (glyph for glyph in fl.font.glyphs if glyph.name.startswith('a'))
for glyph in glyphs:
  harmonize_curves(glyph)  

-------------------------------------------------------------------------------
```

#### Credits

The method for `balance_curves()` is based on Jens Kutilek's [Curve Equalizer](https://github.com/jenskutilek/Curve-Equalizer) for RoboFont.

The method for `harmonize_curves()` is based on Linus Romer's [Curvatura](https://github.com/linusromer/curvatura) for FontForge.

#### Author

Jameson R Spires

#### License

Any methods not described in the credits section are covered under the [MIT License](https://opensource.org/licenses/MIT).

#### Version history
* version 0.2.0  
  implemented harmonizing for curves which begin with a curve point  

* version 0.1.5  
  small changes  

* version 0.1.4  
  conversion to C++  
  creation of FontLab installer  

* version 0.1.3  
  recompilation  

* version 0.1.1  
  revised `harmonize_curves()` function  

* version 0.1.0  
  initial release  
