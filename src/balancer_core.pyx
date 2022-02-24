# coding: utf-8
# cython: language_level=2
# cython: wraparound=False, boundscheck=False
# cython: infer_types=True, cdivision=True, auto_pickle=False
# distutils: language=c++
# distutils: extra_compile_args=[-std=c++0x, -Os, -Wall, -Wno-format, -ffast-math, -fno-strict-aliasing]

from FL import fl

from cython.operator cimport postincrement as postincr

cdef f64 MIN = 1.0 if fl.font.upm < 2048 else 3.0

MOVE = 17

def harmonize_curves(glyph):
  nodes = glyph.nodes
  if nodes:
    active = glyph.Layer(fl.master)
    if glyph.isAnySelected():
      _harmonize_selected_curves(nodes, active)
    else:
      _harmonize_all_curves(nodes, active)


def balance_curves(glyph):
  nodes = glyph.nodes
  if nodes:
    active = glyph.Layer(fl.master)
    if glyph.isAnySelected():
      _balance_selected_curves(nodes, active)
    else:
      _balance_all_curves(nodes, active)


cdef void _harmonize_curve_pair(active, ssize p0_i, ssize p1_i, ssize p2_i, ssize p3_i, ssize p4_i, ssize p5_i, ssize p6_i, ssize pmove_i):
  p0 = PySequence_ITEM(active, p0_i)
  p1 = PySequence_ITEM(active, p1_i)
  p2 = PySequence_ITEM(active, p2_i)
  p3 = PySequence_ITEM(active, p3_i)
  p4 = PySequence_ITEM(active, p4_i)
  p5 = PySequence_ITEM(active, p5_i)
  p6 = PySequence_ITEM(active, p6_i)
  if pmove_i > -1:
    pmove = PySequence_ITEM(active, pmove_i)
  cdef i32 p0_x = p0.x, p0_y = p0.y
  cdef i32 p1_x = p1.x, p1_y = p1.y
  cdef i32 p2_x = p2.x, p2_y = p2.y
  cdef i32 p3_x = p3.x, p3_y = p3.y
  cdef i32 p4_x = p4.x, p4_y = p4.y
  cdef i32 p5_x = p5.x, p5_y = p5.y
  cdef i32 p6_x = p6.x, p6_y = p6.y
  cdef cpp_curve curve = cpp_curve(p0_x, p0_y, p1_x, p1_y, p2_x, p2_y, p3_x, p3_y)
  cdef cpp_curve curve_next = cpp_curve(p3_x, p3_y, p4_x, p4_y, p5_x, p5_y, p6_x, p6_y)

  curve.harmonize(curve_next)
  if curve.harmonized:
    if curve.horizontal and fabs(curve.p3.x - p3_x) > MIN:
      p3.x = PyInt_FromLong(<i32>curve.p3.x)
      if pmove_i > -1:
        pmove.x = PyInt_FromLong(<i32>curve.p3.x)
    elif fabs(curve.p3.y - p3_y) > MIN:
      p3.y = PyInt_FromLong(<i32>curve.p3.y)
      if pmove_i > -1:
        pmove.y = PyInt_FromLong(<i32>curve.p3.y)


cdef void _harmonize_all_curves(nodes, active):
  cdef ssize i = 0, j = 0, prev_i = 0, node_i = 0
  cdef ssize end_i = 0, start_i = 0, next_i = 0
  cdef ssize nodes_n = PySequence_Size(nodes)
  cdef ssize active_n = PySequence_Size(active)
  cdef ssize contours_n = 0
  cdef pod_vector[cpp_point_indices] points
  cdef pod_vector[ssize] contour_lens
  points.reserve(active_n)
  contour_lens.reserve(nodes_n // 2)

  for node_i in range(nodes_n):
    node = PySequence_ITEM(nodes, node_i)
    if node.type == MOVE:
      if node_i:
        contour_lens.push_back(node_i - start_i)
      postincr(contours_n)
      start_i = node_i
    j = node.count
    if j > 1:
      points[node_i] = cpp_point_indices(prev_i, i + 1, i + 2, i)
      if i + 5 < active_n:
        _harmonize_curve_pair(active, prev_i, i + 1, i + 2, i, i + 4, i + 5, i + 3, -1)
    prev_i = i
    i += j
  contour_lens.push_back(node_i + 1 - start_i)

  start_i = 0
  for i in range(contours_n):
    end_i = start_i + contour_lens[i] - 1
    next_i = start_i + 1
    start_node = PySequence_ITEM(nodes, start_i)
    end_node = PySequence_ITEM(nodes, end_i)
    start_i = end_i + 1
    if start_node.points[0] == end_node.points[0]:
      end, next = points[end_i], points[next_i]
      if end[0] != -1 and next[0] != -1:
        _harmonize_curve_pair(active, end[0], end[1], end[2], end[3], next[1], next[2], next[3], next[0])


cdef void _harmonize_selected_curves(nodes, active):
  cdef ssize i = 0, j = 0, prev_i = 0, node_i = 0
  cdef ssize end_i = 0, start_i = 0, next_i = 0
  cdef ssize nodes_n = PySequence_Size(nodes)
  cdef ssize active_n = PySequence_Size(active)
  cdef ssize contours_n = 0
  cdef pod_vector[cpp_point_indices] points
  cdef pod_vector[ssize] contour_lens
  points.reserve(active_n)
  contour_lens.reserve(nodes_n // 2)

  for node_i in range(nodes_n):
    node = PySequence_ITEM(nodes, node_i)
    if node.type == MOVE:
      if node_i:
        contour_lens.push_back(node_i - start_i)
      postincr(contours_n)
      start_i = node_i
    j = node.count
    if j > 1:
      points[node_i] = cpp_point_indices(prev_i, i + 1, i + 2, i)
      if i + 5 < active_n and node.selected:
        _harmonize_curve_pair(active, prev_i, i + 1, i + 2, i, i + 4, i + 5, i + 3, -1)
    prev_i = i
    i += j
  contour_lens.push_back(node_i + 1 - start_i)

  start_i = 0
  for i in range(contours_n):
    end_i = start_i + contour_lens[i] - 1
    next_i = start_i + 1
    start_node = PySequence_ITEM(nodes, start_i)
    end_node = PySequence_ITEM(nodes, end_i)
    next_node = PySequence_ITEM(nodes, next_i)
    start_i = end_i + 1
    if not end_node.selected:
      continue
    if start_node.points[0] == end_node.points[0]:
      end, next = points[end_i], points[next_i]
      if end[0] != -1 and next[0] != -1:
        _harmonize_curve_pair(active, end[0], end[1], end[2], end[3], next[1], next[2], next[3], next[0])


cdef void _balance_curve(active, ssize p0_i, ssize p1_i, ssize p2_i, ssize p3_i):
  p0 = PySequence_ITEM(active, p0_i)
  p1 = PySequence_ITEM(active, p1_i)
  p2 = PySequence_ITEM(active, p2_i)
  p3 = PySequence_ITEM(active, p3_i)
  cdef i32 p0_x = p0.x, p0_y = p0.y
  cdef i32 p1_x = p1.x, p1_y = p1.y
  cdef i32 p2_x = p2.x, p2_y = p2.y
  cdef i32 p3_x = p3.x, p3_y = p3.y
  cdef cpp_curve curve = cpp_curve(p0_x, p0_y, p1_x, p1_y, p2_x, p2_y, p3_x, p3_y)

  curve.balance()
  if curve.balanced:
    if fabs(curve.p1.x - p1_x) > MIN or fabs(curve.p1.y - p1_y) > MIN:
      p1.x = PyInt_FromLong(<i32>curve.p1.x)
      p1.y = PyInt_FromLong(<i32>curve.p1.y)
    if fabs(curve.p2.x - p2_x) > MIN or fabs(curve.p2.y - p2_y) > MIN:
      p2.x = PyInt_FromLong(<i32>curve.p2.x)
      p2.y = PyInt_FromLong(<i32>curve.p2.y)


cdef void _balance_all_curves(nodes, active):
  cdef ssize i = 0, j = 0, prev_i = 0, node_i = 0, n = PySequence_Size(nodes)

  for node_i in range(n):
    node = PySequence_ITEM(nodes, node_i)
    j = node.count
    if j > 1:
      _balance_curve(active, prev_i, i + 1, i + 2, i)
    prev_i = i
    i += j


cdef void _balance_selected_curves(nodes, active):
  cdef ssize i = 0, j = 0, prev_i = 0, node_i = 0, n = PySequence_Size(nodes)

  for node_i in range(n):
    node = PySequence_ITEM(nodes, node_i)
    j = node.count
    if j > 1 and node.selected:
      _balance_curve(active, prev_i, i + 1, i + 2, i)
    prev_i = i
    i += j
