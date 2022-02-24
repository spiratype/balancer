// balancer_core.hpp

#pragma once

#include <fenv.h>
#include <math.h>
#include <stddef.h>
#include <stdlib.h>

typedef size_t usize;
typedef double f64;
typedef signed long i32;
typedef signed long ssize;

const usize npos = -1;

template<typename any_t>
struct pod_vector {
  any_t* m_ptr;
  usize m_len, m_cap;
  pod_vector() : m_ptr(NULL), m_len(0), m_cap(0) {}
  ~pod_vector() {
    if (m_ptr)
      free(m_ptr);
    }
  void reserve(usize cap) {
    if (!m_ptr) {
      m_ptr = (any_t*)malloc(cap * sizeof(any_t));
      for (usize i = 0; i < cap; i++)
        m_ptr[i] = any_t();
      m_cap = cap;
      }
    else if (cap > m_cap) {
      m_ptr = (any_t*)realloc((void*)m_ptr, cap * sizeof(any_t));
      for (usize i = m_cap; i < cap; i++)
        m_ptr[i] = any_t();
      m_cap = cap;
      }
    }
  usize find(const any_t &val) const {
    if (!m_len)
      return npos;
    for (usize i; i < m_len; i++)
      if (m_ptr[i] == val)
        return i;
    return npos;
    }
  void push_back(const any_t &val) {
    if (m_len + 1 >= m_cap)
      this->reserve(m_cap++);
    m_ptr[m_len++] = val;
    }
  usize size() const {
    return m_len;
    }
  any_t& operator[](usize i) {
    return m_ptr[i];
    }
  };


namespace balancer {

const f64 M_PI = 3.14159265359;
const f64 M_1DEG = 0.01745329252;
const f64 M_3DEG = 0.05235987756;

struct point {
  f64 x, y;
  bool harmonized;
  point() : x(0.0), y(0.0), harmonized(false) {}
  point(f64 x, f64 y) : x(x), y(y), harmonized(false) {}
  f64 distance(const point &other) const {
    return hypot(this->x - other.x, this->y - other.y);
    }
  f64 angle(const point &other) const {
    return atan2(other.y - this->y, other.x - this->x);
    }
  };


struct point_indices {
  ssize m_indices[4];
  point_indices() : m_indices({-1, 0, 0, 0}) {}
  point_indices(ssize a, ssize b, ssize c, ssize d) : m_indices({a, b, c, d}) {}
  ssize operator[](usize i) {
    return m_indices[i];
    }
  };


struct handles {
  f64 a, b;
  handles() : a(0.0), b(0.0) {}
  handles(f64 a, f64 b) : a(a), b(b) {}
  };


struct curve {
  balancer::point p0, p1, p2, p3;
  bool balanced, harmonized, horizontal;
  curve() {}
  curve(f64 p0x, f64 p0y, f64 p1x, f64 p1y, f64 p2x, f64 p2y, f64 p3x, f64 p3y) :
      p0(p0x, p0y), p1(p1x, p1y), p2(p2x, p2y), p3(p3x, p3y), balanced(false), harmonized(false), horizontal(false) {}
  void balance();
  void harmonize(const balancer::curve &next);
  f64 handle_ratio(const f64 a, const f64 c) const {
    return ((this->p3.distance(this->p2) / a) + (this->p0.distance(this->p1) / c)) / 2.0;
    }
  balancer::point harmonized_point(const balancer::curve &next) const;
  };


static void move_handle_point(balancer::point &handle_point, const balancer::point &b, const balancer::point &c, const f64 distance) {
  f64 alpha = 0.0, beta = 0.0;

  if (handle_point.x == b.x and handle_point.y == b.y) {
    alpha = c.y - b.y;
    beta = c.x - b.x;
    }
  else {
    alpha = handle_point.y - b.y;
    beta = handle_point.x - b.x;
    }

  const f64 phi = atan2(alpha, beta);
  handle_point.x = nearbyint(b.x + (cos(phi) * distance));
  handle_point.y = nearbyint(b.y + (sin(phi) * distance));
  }


balancer::handles balanced_handles(const balancer::curve &curve, const f64 p0_p1, const f64 p0_p3) {
  const f64 alpha = p0_p3 - p0_p1;
  const f64 gamma = atan2(curve.p3.x - curve.p0.x, curve.p3.y - curve.p0.y) -
      atan2(curve.p3.x - curve.p2.x, curve.p3.y - curve.p2.y);
  const f64 beta = M_PI - alpha - gamma;
  const f64 sin_beta = sin(beta);
  const f64 b = curve.p0.distance(curve.p3);
  const f64 a = b * sin(alpha) / sin_beta;
  const f64 c = b * sin(gamma) / sin_beta;
  const f64 ratio = curve.handle_ratio(a, c);
  return balancer::handles(a * ratio, c * ratio);
  }


void curve::harmonize(const balancer::curve &next_curve) {
  this->harmonized = false;
  this->horizontal = this->p2.y == next_curve.p1.y;
  const bool vertical = this->p2.x == next_curve.p1.x;
  balancer::point p;

  if (this->horizontal or vertical) {

    p = this->harmonized_point(next_curve);
    this->harmonized = true;

    if (this->horizontal)
      this->p3.x = nearbyint(p.x);
    else
      this->p3.y = nearbyint(p.y);
    }
  }


void curve::balance() {
  const bool both_vertical = (this->p1.y - this->p0.y) == 0.0 and (this->p2.y - this->p3.y) == 0.0;
  const bool both_horizontal = (this->p1.x - this->p0.x) == 0.0 and (this->p2.x - this->p3.x) == 0.0;
  this->balanced = false;

  if (both_vertical or both_horizontal)
    return;

  const f64 p0_p3 = this->p0.angle(this->p3);
  const f64 p0_p1 = this->p0.angle(this->p1);
  const f64 p2_p3 = this->p2.angle(this->p3);
  const f64 handle_1 = p0_p3 - p0_p1;
  const f64 handle_2 = p2_p3 - p0_p3;
  const bool both_left_side = handle_1 > M_1DEG and handle_2 > M_1DEG;
  const bool both_right_side = handle_1 < -M_1DEG and handle_2 < -M_1DEG;
  balancer::handles handles;

  if ((both_left_side or both_right_side) and (fabs(handle_1) + fabs(handle_2) >= M_3DEG)) {
    handles = balanced_handles(*this, p0_p1, p0_p3);
    move_handle_point(this->p2, this->p3, this->p1, handles.a);
    move_handle_point(this->p1, this->p0, this->p2, handles.b);
    this->balanced = true;
    }
  }


static inline f64 harmonize_distance(const balancer::point &p0, const balancer::point &p1, const balancer::point &p2) {
  const f64 dx = p2.x - p1.x, dy = p2.y - p1.y;
  return fabs((((p0.y - p1.y) * dx) - ((p0.x - p1.x) * dy)) / hypot(dx, dy));
  }


balancer::point curve::harmonized_point(const balancer::curve &next) const {

  if (this->p2.x == next.p1.x and this->p2.y == next.p1.y)
    return this->p3;

  const f64 d0 = harmonize_distance(this->p1, this->p2, next.p1);
  const f64 d1 = harmonize_distance(next.p2, this->p2, next.p1);

  if (d0 == d1)
    return balancer::point(0.5 * (this->p2.x + next.p1.x), 0.5 * (this->p2.y + next.p1.y));

  const f64 t = (d0 - sqrt(d0 * d1)) / (d0 - d1);
  const f64 t_1 = 1.0 - t;

  return balancer::point(t_1 * this->p2.x + t * next.p1.x, t_1 * this->p2.y + t * next.p1.y);
  }

} // namespace balancer
