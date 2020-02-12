# coding: utf-8
#FLM: balancer
from FL import fl

from balancer_core import balance_curves

__doc__ = '''
multiple master-compatible curve handle equalizer for windows fontlab 5.2

version 1.0
balances cubic bézier handle lengths of a curve segment by extending or
retracting along original angles

balance method from Jens Kutilek's Curve-Eq for RoboFont
https://github.com/jenskutilek/Curve-Equalizer

Jameson Spires - jameson@spiratype.com
'''

fl.SetUndo()
balance_curves(fl.glyph)
fl.UpdateGlyph()
