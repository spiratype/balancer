ctypedef struct cPoint:
	double x
	double y
	size_t index

ctypedef struct cCurve:
	cPoint p0
	cPoint p1
	cPoint p2
	cPoint p3
	size_t index
	size_t prev_index
	bint balanced
	bint harmonized

cdef vector[cPoint] Points(list points):
	cdef:
		size_t n = <size_t>PyList_GET_SIZE(points)
		vector[cPoint] cpp_points
		object point

	cpp_points.reserve(n)
	for point in points:
		cpp_points.push_back(Point(point.x, point.y, 0))
	return cpp_points

cdef inline cPoint Point(double x, double y, int index) nogil:
	cdef cPoint point = [x, y, index]
	return point

cdef inline cCurve Curve(cPoint p0, cPoint p1, cPoint p2, cPoint p3, size_t index, size_t prev_index) nogil:
	cdef cCurve curve = [p0, p1, p2, p3, index, prev_index, 0, 0]
	return curve

cdef void balance(cCurve &curve) nogil:
	cdef:
		bint both_vertical = (curve.p1.y - curve.p0.y) == 0.0 and (curve.p2.y - curve.p3.y) == 0.0
		bint both_horizontal = (curve.p1.x - curve.p0.x) == 0.0 and (curve.p2.x - curve.p3.x) == 0.0
		double ratio = 0.0

	curve.balanced = 0

	if both_vertical or both_horizontal:
		return

	cdef:
		double p0_p3 = angle(curve.p0, curve.p3)
		double p0_p1 = angle(curve.p0, curve.p1)
		double p2_p3 = angle(curve.p2, curve.p3)
		double handle_1 = p0_p3 - p0_p1
		double handle_2 = p2_p3 - p0_p3
		bint both_left_side = handle_1 > M_1DEG and handle_2 > M_1DEG
		bint both_right_side = handle_1 < -M_1DEG and handle_2 < -M_1DEG

	if both_left_side or both_right_side:

		if (fabs(handle_1) + fabs(handle_2)) >= M_3DEG:

			handle_1, handle_2 = curve_sides(curve, p0_p1, p0_p3)

			move_handles(curve.p2, curve.p3, curve.p1, handle_1)
			move_handles(curve.p1, curve.p0, curve.p2, handle_2)

			curve.balanced = 1

cdef (double, double) curve_sides(cCurve &curve, double &p0_p1, double &p0_p3) nogil:
	cdef:
		double alpha = p0_p3 - p0_p1
		double gamma = atan2(curve.p3.x - curve.p0.x, curve.p3.y - curve.p0.y) - atan2(curve.p3.x - curve.p2.x, curve.p3.y - curve.p2.y)
		double beta = M_PI - alpha - gamma
		double sin_beta = sin(beta)
		double b = distance(curve.p0, curve.p3)
		double a = b * sin(alpha) / sin_beta
		double c = b * sin(gamma) / sin_beta
		double ratio = handle_ratio(curve, a, c)
	return a * ratio, c * ratio

cdef void move_handles(cPoint &handle_point, cPoint &b, cPoint &c, double distance) nogil:
	cdef:
		double alpha = 0.0
		double beta = 0.0

	if handle_point.x == b.x and handle_point.y == b.y:
		alpha = c.y - b.y
		beta = c.x - b.x
	else:
		alpha = handle_point.y - b.y
		beta = handle_point.x - b.x

	cdef double phi = atan2(alpha, beta)
	handle_point.x = b.x + (cos(phi) * distance)
	handle_point.y = b.y + (sin(phi) * distance)

cdef inline double handle_ratio(cCurve &curve, double &a, double &c) nogil:
	return ((distance(curve.p3, curve.p2) / a) + (distance(curve.p0, curve.p1) / c)) / 2.0

cdef inline double sideness(cPoint &a, cPoint &b, cPoint &c) nogil:
	return ((b.x - a.x) * (c.y - a.y)) - ((c.x - a.x) * (b.y - a.y))

cdef inline double distance(cPoint &a, cPoint &b) nogil:
	return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2))

cdef inline double angle(cPoint &a, cPoint &b) nogil:
	return atan2(b.y - a.y, b.x - a.x)
