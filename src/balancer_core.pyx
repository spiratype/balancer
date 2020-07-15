# coding: utf-8
# cython: language_level=2
# cython: boundscheck=False
# cython: wraparound=False
# cython: cdivision=True
# distutils: language=c++
# distutils: extra_compile_args=[-O3, -fno-strict-aliasing]
from FL import fl

from libcpp cimport bool
from libcpp.vector cimport vector

cdef extern from '<fenv.h>':
	const int FE_TONEAREST
	int fesetround(int)

cdef extern from 'balancer_core.hpp' nogil:
	cppclass cpp_point:
		double x
		double y
		size_t index
		cpp_point()
		cpp_point(double, double)
		cpp_point(double, double, size_t)

	cppclass cpp_curve:
		cpp_point p0
		cpp_point p1
		cpp_point p2
		cpp_point p3
		size_t index
		size_t prev_index
		bool balanced
		bool harmonized
		cpp_curve()
		cpp_curve(cpp_point, cpp_point, cpp_point, cpp_point, size_t, size_t)
		void balance()
		cpp_point harmonize(cpp_curve)

	void harmonize(cpp_curve, cpp_curve)

def harmonize_curves(glyph):
	_harmonize_curves(glyph, glyph.isAnySelected())

def balance_curves(glyph):
	_balance_curves(glyph, glyph.isAnySelected())

cdef vector[cpp_point] convert_points(points):

	cdef vector[cpp_point] cpp_points

	cpp_points.reserve(len(points))
	for point in points:
		cpp_points.push_back(cpp_point(point.x, point.y))
	return cpp_points

cdef void _harmonize_curves(glyph, bint selected):
	cdef:
		vector[cpp_point] active = convert_points(glyph.Layer(fl.master))
		vector[cpp_curve] curves = collect_curves(glyph, selected, active)
		cpp_curve curve
		size_t i = 0
		size_t prev_i = 0

	fesetround(FE_TONEAREST)
	for curve in curves:
		if i:
			if curve.index - curve.prev_index == 3:
				harmonize_curve(glyph, curves[prev_i], curve)
		prev_i = i
		i += 1

cdef void _balance_curves(glyph, bint selected):
	cdef:
		vector[cpp_point] active = convert_points(glyph.Layer(fl.master))
		vector[cpp_curve] curves = collect_curves(glyph, selected, active)
		cpp_curve curve

	fesetround(FE_TONEAREST)
	for curve in curves:
		balance_curve(glyph, curve)

cdef void harmonize_curve(glyph, cpp_curve &curve, cpp_curve &next_curve):
	harmonize(curve, next_curve)
	if curve.harmonized:
		active = glyph.Layer(fl.master)
		active[curve.p3.index].x, active[curve.p3.index].y = int(curve.p3.x), int(curve.p3.y)
		glyph.modified = 1
		fl.font.modified = 1

cdef void balance_curve(glyph, cpp_curve &curve):
	curve.balance()
	if curve.balanced:
		active = glyph.Layer(fl.master)
		active[curve.p1.index].x, active[curve.p1.index].y = int(curve.p1.x), int(curve.p1.y)
		active[curve.p2.index].x, active[curve.p2.index].y = int(curve.p2.x), int(curve.p2.y)
		glyph.modified = 1
		fl.font.modified = 1

cdef vector[cpp_curve] collect_curves(glyph, bint selected, vector[cpp_point] &active):
	if selected:
		return selected_curves(glyph.nodes, active)
	return all_curves(glyph.nodes, active)

cdef vector[cpp_curve] selected_curves(nodes, vector[cpp_point] &active):
	cdef:
		vector[cpp_curve] cpp_curves
		size_t i = 0
		size_t prev_i = 0
		size_t prev_curve_i = 0
		size_t j = 0
		size_t p0_i = 0
		size_t p1_i = 0
		size_t p2_i = 0
		size_t p3_i = 0

	cpp_curves.reserve(len(nodes))
	for node in nodes:
		j = node.count
		if node.selected:
			if j > 1:
				p0_i = prev_i
				p1_i = i+1
				p2_i = i+2
				p3_i = i
				cpp_curves.push_back(
					cpp_curve(
						cpp_point(active[p0_i].x, active[p0_i].y, p0_i),
						cpp_point(active[p1_i].x, active[p1_i].y, p1_i),
						cpp_point(active[p2_i].x, active[p2_i].y, p2_i),
						cpp_point(active[p3_i].x, active[p3_i].y, p3_i),
						i,
						prev_curve_i,
						))
				prev_curve_i = i
		prev_i = i
		i += j

	return cpp_curves

cdef vector[cpp_curve] all_curves(nodes, vector[cpp_point] &active):
	cdef:
		vector[cpp_curve] cpp_curves
		size_t i = 0
		size_t prev_i = 0
		size_t prev_curve_i = 0
		size_t j = 0
		size_t p0_i = 0
		size_t p1_i = 0
		size_t p2_i = 0
		size_t p3_i = 0

	cpp_curves.reserve(len(nodes))
	for node in nodes:
		j = node.count
		if j > 1:
			p0_i = prev_i
			p1_i = i+1
			p2_i = i+2
			p3_i = i
			cpp_curves.push_back(
				cpp_curve(
					cpp_point(active[p0_i].x, active[p0_i].y, p0_i),
					cpp_point(active[p1_i].x, active[p1_i].y, p1_i),
					cpp_point(active[p2_i].x, active[p2_i].y, p2_i),
					cpp_point(active[p3_i].x, active[p3_i].y, p3_i),
					i,
					prev_curve_i,
					))
			prev_curve_i = i
		prev_i = i
		i += j

	return cpp_curves
