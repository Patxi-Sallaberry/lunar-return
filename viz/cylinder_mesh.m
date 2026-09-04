function [X, Y, Z] = cylinder_mesh(p1, p2, r, nSide)
%CYLINDER_MESH  Surface mesh of a capped cylinder between two points.
%   [X,Y,Z] = CYLINDER_MESH(p1, p2, r, nSide) returns 2 x (nSide+1) grids
%   suitable for SURF. Used to render the manipulator links as solids instead
%   of bare lines, which reads far better in a 1080p video frame.

if nargin < 4, nSide = 20; end
p1 = p1(:); p2 = p2(:);
a = p2 - p1;
L = norm(a);
if L < eps
    a = [0;0;1]; L = eps;
end
u = a / max(L, eps);

% Any vector not parallel to u works as a seed for the transverse basis.
seed = [1;0;0];
if abs(dot(seed, u)) > 0.9
    seed = [0;1;0];
end
v = cross(u, seed); v = v / norm(v);
w = cross(u, v);

th = linspace(0, 2*pi, nSide+1);
ring = r * (v * cos(th) + w * sin(th));

X = [p1(1) + ring(1,:); p2(1) + ring(1,:)];
Y = [p1(2) + ring(2,:); p2(2) + ring(2,:)];
Z = [p1(3) + ring(3,:); p2(3) + ring(3,:)];
end
