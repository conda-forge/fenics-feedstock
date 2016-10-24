from dolfin import *

mesh = UnitSquareMesh(2,2)
V = FunctionSpace(mesh, "CG", 1)
u = project(Expression("x[0]", degree=1), V)
