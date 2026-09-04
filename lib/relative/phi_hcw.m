function Phi = phi_hcw(t, n)
%PHI_HCW  6x6 state transition matrix of the Hill-Clohessy-Wiltshire equations.
%
%   AXIS CONVENTION (non-standard, used consistently across this repository):
%       x = along-track (V-bar), positive along the target's velocity
%       y = cross-track (out of plane)
%       z = radial (R-bar), positive outward
%
%   so the linearised relative dynamics read
%       xdd - 2 n zdot            = 0
%       ydd + n^2 y               = 0
%       zdd + 2 n xdot - 3 n^2 z  = 0
%
%   State ordering is dx = [x; y; z; xdot; ydot; zdot] and PHI_HCW(0, n) = I6.
%
%   Note the Coriolis signs: they are the mirror image of the textbook
%   radial/along-track ordering, which is exactly what swapping the roles of
%   the radial and along-track axes does to the cross product.

tau = n * t;
s = sin(tau);
c = cos(tau);

Phi = [ 1,      0,   6*(tau - s),      (4*s - 3*tau)/n,  0,   2*(1 - c)/n;
        0,      c,   0,                0,                s/n, 0;
        0,      0,   4 - 3*c,          2*(c - 1)/n,      0,   s/n;
        0,      0,   6*n*(1 - c),      4*c - 3,          0,   2*s;
        0,   -n*s,   0,                0,                c,   0;
        0,      0,   3*n*s,            -2*s,             0,   c ];
end
