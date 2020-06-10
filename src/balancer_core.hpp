// balancer_core.hpp

#include <math.h>
#include <stddef.h>
#include <vector>

const double M_1DEG = 0.01745329252;
const double M_3DEG = 0.05235987756;

class cpp_curve;

class cpp_handles {
	public:
		double a;
		double b;
		cpp_handles() {};
		cpp_handles(double a, double b) {
			this->a = a;
			this->b = b;
			};
	};

class cpp_point {
	public:
		double x;
		double y;
		size_t index;
		cpp_point() {};
		cpp_point(double x, double y, size_t index=0) {
			this->x = x;
			this->y = y;
			this->index = index;
			}
		double distance(cpp_point &other) {
			return sqrt(pow(this->x - other.x, 2) + pow(this->y - other.y, 2));
			}
		double angle(cpp_point &other) {
			return atan2(other.y - this->y, other.x - this->x);
			}
	};

cpp_handles curve_sides(cpp_curve &curve, double &p0_p1, double &p0_p3);
void move_handles(cpp_point &handle_point, cpp_point &b, cpp_point &c, double distance);
double harmonize_distance(cpp_point &p0, cpp_point &p1, cpp_point &p2);

class cpp_curve {
	public:
		cpp_point p0;
		cpp_point p1;
		cpp_point p2;
		cpp_point p3;
		size_t index;
		size_t prev_index;
		bool balanced;
		bool harmonized;
		cpp_curve() {};
		cpp_curve(
			cpp_point p0,
			cpp_point p1,
			cpp_point p2,
			cpp_point p3,
			size_t index,
			size_t prev_index
			) {
			this->p0 = p0;
			this->p1 = p1;
			this->p2 = p2;
			this->p3 = p3;
			this->index = index;
			this->prev_index = prev_index;
			}

		void balance() {
			bool both_vertical = (this->p1.y - this->p0.y) == 0.0 and (this->p2.y - this->p3.y) == 0.0;
			bool both_horizontal = (this->p1.x - this->p0.x) == 0.0 and (this->p2.x - this->p3.x) == 0.0;
			this->balanced = false;

			if (both_vertical or both_horizontal) return;

			double p0_p3 = this->p0.angle(this->p3);
			double p0_p1 = this->p0.angle(this->p1);
			double p2_p3 = this->p2.angle(this->p3);
			double handle_1 = p0_p3 - p0_p1;
			double handle_2 = p2_p3 - p0_p3;
			bool both_left_side = handle_1 > M_1DEG and handle_2 > M_1DEG;
			bool both_right_side = handle_1 < -M_1DEG and handle_2 < -M_1DEG;
			cpp_handles handles;

			if (both_left_side or both_right_side) {
				if (fabs(handle_1) + fabs(handle_2) >= M_3DEG) {
					handles = this->curve_sides(p0_p1, p0_p3);
					move_handles(this->p2, this->p3, this->p1, handles.a);
					move_handles(this->p1, this->p0, this->p2, handles.b);
					this->balanced = 1;
					}
				}
			}

		cpp_handles curve_sides(double &p0_p1, double &p0_p3) {
			double alpha = p0_p3 - p0_p1;
			double gamma = atan2(this->p3.x - this->p0.x, this->p3.y - this->p0.y) -
				atan2(this->p3.x - this->p2.x, this->p3.y - this->p2.y);
			double beta = M_PI - alpha - gamma;
			double sin_beta = sin(beta);
			double b = p0.distance(this->p3);
			double a = b * sin(alpha) / sin_beta;
			double c = b * sin(gamma) / sin_beta;
			double ratio = this->handle_ratio(a, c);
			cpp_handles handles = cpp_handles(a * ratio, c * ratio);
			return handles;
			}

		double handle_ratio(double &a, double &c) {
			return ((this->p3.distance(this->p2) / a) + (this->p0.distance(this->p1) / c)) / 2.0;
			}

		cpp_point harmonize(cpp_curve &other) {

			if (this->p2.x == other.p1.x and this->p2.y == other.p1.y) return this->p3;

			double d0 = harmonize_distance(this->p1, this->p2, other.p1);
			double d1 = harmonize_distance(other.p2, this->p2, other.p1);

			if (d0 == d1) return cpp_point(0.5 * (this->p2.x + other.p1.x),
					0.5 * (this->p2.y + other.p1.y));

			double t = (d0 - sqrt(d0 * d1)) / (d0 - d1);
			double t_1 = 1.0 - t;

			return cpp_point(t_1 * this->p2.x + t * other.p1.x, t_1 * this->p2.y + t * other.p1.y);
			}
	};


void move_handles(cpp_point &handle_point, cpp_point &b, cpp_point &c, double distance) {
	double alpha = 0.0;
	double beta = 0.0;
	double phi = 0.0;

	if (handle_point.x == b.x and handle_point.y == b.y) {
		alpha = c.y - b.y;
		beta = c.x - b.x;
		}
	else {
		alpha = handle_point.y - b.y;
		beta = handle_point.x - b.x;
		}

	phi = atan2(alpha, beta);
	handle_point.x = nearbyint(b.x + (cos(phi) * distance));
	handle_point.y = nearbyint(b.y + (sin(phi) * distance));
	}

void harmonize(cpp_curve &curve, cpp_curve &next_curve) {
	bool horizontal = curve.p2.y == next_curve.p1.y;
	bool vertical = curve.p2.x == next_curve.p1.x;
	cpp_point p3;

	curve.harmonized = false;

	if (horizontal or vertical) {

		p3 = curve.harmonize(next_curve);
		curve.harmonized = true;

		if (horizontal) {
			curve.p3.x = nearbyint(p3.x);
			}
		else {
			curve.p3.y = nearbyint(p3.y);
			}
		}
	}

double harmonize_distance(cpp_point &p0, cpp_point &p1, cpp_point &p2) {
	double i = p2.x - p1.x;
	double j = p2.y - p1.y;
	return fabs((((p0.y - p1.y) * i) - ((p0.x - p1.x) * j)) / sqrt(pow(i, 2) + pow(j, 2)));
	}
