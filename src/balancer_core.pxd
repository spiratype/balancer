# balancer_core.pxd

ctypedef size_t usize
ctypedef Py_ssize_t ssize
ctypedef double f64
ctypedef signed long i32

cdef extern from "python.h":
  object PySequence_ITEM(object, ssize)
  ssize PySequence_Size(object)
  object PyInt_FromLong(i32)

cdef extern from "balancer_core.hpp" nogil:
  f64 fabs(f64)

  int FE_TONEAREST
  int fesetround(int)

  cppclass pod_vector[T]:
    pod_vector()
    void reserve(usize)
    void push_back(T)
    usize size()
    T& operator[](usize)

  cppclass cpp_point "balancer::point":
    f64 x, y
    bint harmonized
    cpp_point()
    cpp_point(f64, f64)

  cppclass cpp_point_indices "balancer::point_indices":
    cpp_point_indices()
    cpp_point_indices(ssize, ssize, ssize, ssize)
    ssize operator[](usize)

  cppclass cpp_curve "balancer::curve":
    cpp_point p0, p1, p2, p3
    bint balanced, harmonized, horizontal
    cpp_curve()
    cpp_curve(f64, f64, f64, f64, f64, f64, f64, f64)
    void balance()
    void harmonize(cpp_curve)
