cdef void harmonize(cCurve &curve, cCurve &next_curve) nogil:
	cdef:
		bint horizontal = curve.p2.y == next_curve.p1.y
		bint vertical = curve.p2.x == next_curve.p1.x
		double ratio = 0.0
		double shift = 0.0

	curve.harmonized = 0

	if horizontal or vertical:

		ratio = harmonize_ratio(curve, next_curve)

		if horizontal:
			shift = (next_curve.p1.x - curve.p2.x) * ratio
			if fabs(shift - (curve.p3.x - curve.p2.x)) > 1:
				curve.p3.x = curve.p2.x + shift
				curve.harmonized = 1
		elif vertical:
			shift = (next_curve.p1.y - curve.p2.y) * ratio
			if fabs(shift - (curve.p3.y - curve.p2.y)) > 1:
				curve.p3.y = curve.p2.y + shift
				curve.harmonized = 1

cdef (double, double) intersection(cPoint &p1, cPoint &p2, cPoint &p3, cPoint &p4) nogil:
	cdef:
		double p1x_p2x = p1.x - p2.x
		double p3x_p4x = p3.x - p4.x
		double p1y_p2y = p1.y - p2.y
		double p3y_p4y = p3.y - p4.y
		double p1x_p2y = p1.x * p2.y
		double p1y_p2x = p1.y * p2.x
		double p3x_p4y = p3.x * p4.y
		double p3y_p4x = p3.y * p4.x
		double x = ((p1x_p2y - p1y_p2x) * p3x_p4x) - ((p3x_p4y - p3y_p4x) * p1x_p2x)
		double y = ((p1x_p2y - p1y_p2x) * p3y_p4y) - ((p3x_p4y - p3y_p4x) * p1y_p2y)
		double d = (p1x_p2x * p3y_p4y) - (p1y_p2y * p3x_p4x)
	return x / d, y / d

cdef double harmonize_ratio(cCurve &curve, cCurve &next_curve) nogil:
	cdef:
		(double, double) i = intersection(curve.p1, curve.p2, next_curve.p1, next_curve.p2)
		double a = determinant(curve.p1.x, curve.p1.y, curve.p2.x, curve.p2.y)
		double b = determinant(curve.p2.x, curve.p2.y, i[0], i[1])
		double c = determinant(i[0], i[1], next_curve.p1.x, next_curve.p1.y)
		double d = determinant(next_curve.p1.x, next_curve.p1.y, next_curve.p2.x, next_curve.p2.y)
		double p = sqrt(fabs((a / b) * (c / d)))
	return p / (p + 1.0)

cdef inline double determinant(double a, double b, double c, double d) nogil:
	return (a * d) - (b * c)
