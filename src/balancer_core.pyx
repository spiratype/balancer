# coding: utf-8
# cython: language_level=2
# cython: boundscheck=False
# cython: wraparound=False
# cython: cdivision=True
# distutils: language=c++

cdef object fl
from FL import fl

from libcpp.vector cimport vector

cdef extern from '<Python.h>':
	Py_ssize_t PyList_GET_SIZE(object list)

cdef extern from '<math.h>' nogil:
	const double M_PI
	double atan2(double y, double x)
	double cos(double x)
	double sin(double x)
	double pow(double x, double y)
	double sqrt(double x)
	double fabs(double x)
	double nearbyint(double x)

cdef extern from '<fenv.h>' nogil:
	const int FE_TONEAREST
	int fesetround(int mode)
	int fegetround()

cdef int FE_MODE = fegetround()

cdef extern from *:
	'''
	#define M_1DEG 0.01745329251994329577
	#define M_3DEG 0.05235987755982988731
	'''
	const double M_1DEG
	const double M_3DEG

include 'balance.pxi'
include 'harmonize.pxi'

def harmonize_curves(glyph):
	_harmonize_curves(glyph, glyph.isAnySelected())

def balance_curves(glyph):
	_balance_curves(glyph, glyph.isAnySelected())

cdef void _harmonize_curves(object glyph, bint selected):
	cdef:
		vector[cPoint] active = Points(glyph.Layer(fl.master))
		vector[cCurve] curves = collect_curves(glyph, selected, active)
		size_t i = 0
		size_t prev_i = 0

	fesetround(FE_TONEAREST)
	for curve in curves:
		if i:
			if curve.index - curve.prev_index == 3:
				harmonize_curve(glyph, curves[prev_i], curve)
		prev_i = i
		i += 1
	fesetround(FE_MODE)

cdef void _balance_curves(object glyph, bint selected):
	cdef:
		vector[cPoint] active = Points(glyph.Layer(fl.master))
		vector[cCurve] curves = collect_curves(glyph, selected, active)

	fesetround(FE_TONEAREST)
	for curve in curves:
		balance_curve(glyph, curve)
	fesetround(FE_MODE)

cdef void harmonize_curve(object glyph, cCurve &curve, cCurve &next_curve):
	harmonize(curve, next_curve)
	if curve.harmonized:
		active = glyph.Layer(fl.master)
		active[curve.p3.index].x, active[curve.p3.index].y = nearbyint(curve.p3.x), nearbyint(curve.p3.y)
		glyph.modified = 1
		fl.font.modified = 1

cdef void balance_curve(object glyph, cCurve &curve):
	balance(curve)
	if curve.balanced:
		active = glyph.Layer(fl.master)
		active[curve.p1.index].x, active[curve.p1.index].y = nearbyint(curve.p1.x), nearbyint(curve.p1.y)
		active[curve.p2.index].x, active[curve.p2.index].y = nearbyint(curve.p2.x), nearbyint(curve.p2.y)
		glyph.modified = 1
		fl.font.modified = 1

cdef vector[cCurve] collect_curves(object glyph, bint selected, vector[cPoint] &active):
	if selected:
		return selected_curves(glyph.nodes, active)
	return all_curves(glyph.nodes, active)

cdef vector[cCurve] selected_curves(list nodes, vector[cPoint] &active):
	cdef:
		vector[cCurve] cpp_curves
		object node
		size_t n = <size_t>PyList_GET_SIZE(nodes)
		size_t i = 0
		size_t prev_i = 0
		size_t prev_curve_i = 0
		size_t j = 0
		size_t p0_i = 0
		size_t p1_i = 0
		size_t p2_i = 0
		size_t p3_i = 0

	cpp_curves.reserve(<size_t>n)
	for node in nodes:
		j = node.count
		if node.selected:
			if j > 1:
				p0_i = prev_i
				p1_i = i+1
				p2_i = i+2
				p3_i = i
				cpp_curves.push_back(
					Curve(
						Point(active[p0_i].x, active[p0_i].y, p0_i),
						Point(active[p1_i].x, active[p1_i].y, p1_i),
						Point(active[p2_i].x, active[p2_i].y, p2_i),
						Point(active[p3_i].x, active[p3_i].y, p3_i),
						i,
						prev_curve_i,
						))
				prev_curve_i = i
		prev_i = i
		i += j

	cpp_curves.shrink_to_fit()
	return cpp_curves

cdef vector[cCurve] all_curves(list nodes, vector[cPoint] &active):
	cdef:
		vector[cCurve] cpp_curves
		object node
		size_t n = <size_t>PyList_GET_SIZE(nodes)
		size_t i = 0
		size_t prev_i = 0
		size_t prev_curve_i = 0
		size_t j = 0
		size_t p0_i = 0
		size_t p1_i = 0
		size_t p2_i = 0
		size_t p3_i = 0

	cpp_curves.reserve(<size_t>n)
	for node in nodes:
		j = node.count
		if j > 1:
			p0_i = prev_i
			p1_i = i+1
			p2_i = i+2
			p3_i = i
			cpp_curves.push_back(
				Curve(
					Point(active[p0_i].x, active[p0_i].y, p0_i),
					Point(active[p1_i].x, active[p1_i].y, p1_i),
					Point(active[p2_i].x, active[p2_i].y, p2_i),
					Point(active[p3_i].x, active[p3_i].y, p3_i),
					i,
					prev_curve_i,
					))
			prev_curve_i = i
		prev_i = i
		i += j

	cpp_curves.shrink_to_fit()
	return cpp_curves
