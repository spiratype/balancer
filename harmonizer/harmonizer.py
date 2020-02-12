# coding: utf-8
#FLM: harmonizer
from FL import fl

from balancer_core import harmonize_curves

__doc__ = '''
multiple master-compatible curve harmonizer for windows fontlab 5.2

version 1.0
equalizes bézier curvature at extreme vertical/horizontal points

harmonization method from Linus Romer's Curvatura for FontForge
https://github.com/linusromer/curvatura

Jameson Spires - jameson@spiratype.com
'''

fl.SetUndo()
harmonize_curves(fl.glyph)
fl.UpdateGlyph()
