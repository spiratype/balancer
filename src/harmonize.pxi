cdef void harmonize(cCurve &curve, cCurve &next_curve) nogil:
	cdef:
		bint horizontal = curve.p2.y == next_curve.p1.y
		bint vertical = curve.p2.x == next_curve.p1.x
		cPoint p3 = Point(0.0, 0.0, 0)

	curve.harmonized = 0

	if horizontal or vertical:

		p3 = harmonize_cubic(curve, next_curve)

		if horizontal:
			curve.p3.x = p3.x
			curve.harmonized = 1
		else:
			curve.p3.y = p3.y
			curve.harmonized = 1

cdef double harmonize_distance(cPoint &p0, cPoint &p1, cPoint &p2) nogil:
		cdef:
			double i = p2.x - p1.x
			double j = p2.y - p1.y
		return fabs((((p0.y - p1.y) * i) - ((p0.x - p1.x) * j)) / sqrt(pow(i, 2) + pow(j, 2)))

cdef cPoint harmonize_cubic(cCurve &curve, cCurve &next_curve) nogil:

	if curve.p2.x == next_curve.p1.x and curve.p2.y == next_curve.p1.y:
		return curve.p3

	cdef:
		double d0 = harmonize_distance(curve.p1, curve.p2, next_curve.p1)
		double d1 = harmonize_distance(next_curve.p2, curve.p2, next_curve.p1)

	if d0 == d1:
		return Point(.5 * (curve.p2.x + next_curve.p1.x), .5 * (curve.p2.y + next_curve.p1.y), 0)

	cdef:
		double t = (d0 - sqrt(d0 * d1)) / (d0 - d1)
		double t_1 = 1 - t

	return Point(t_1 * curve.p2.x + t * next_curve.p1.x, t_1 * curve.p2.y + t * next_curve.p1.y, 0)
