function Phi = phi_hcw(t, n)
%PHI_HCW  6x6 state transition matrix of the Hill-Clohessy-Wiltshire equations.
%
%   AXIS CONVENTION (used consistently across this repository):
%       x = V-bar, positive in the TRAILING direction  (x = -v_hat)
%       y = cross-track, along the negative orbit normal (y = -h_hat)
%       z = R-bar, radial, positive outward             (z = +r_hat)
%
%   That triad is right-handed: x_hat X y_hat = (-v) X (-h) = v X h = r = z_hat.
%   Expressed in it, the target's orbital angular velocity is -n about the
%   frame's own y axis, which is exactly why the Coriolis terms below carry
%   the opposite sign to the textbook radial/along-track ordering:
%
%       xdd - 2 n zdot            = 0
%       ydd + n^2 y               = 0
%       zdd + 2 n xdot - 3 n^2 z  = 0
%
%   State ordering is dx = [x; y; z; xdot; ydot; zdot] and PHI_HCW(0, n) = I6.
%
%   PHYSICAL SIGN CHECK. Release a chaser 100 m radially outward with zero
%   relative velocity: it is on a higher, slower orbit and must fall BEHIND
%   the target. This STM returns x = +11.3 km after three orbits, i.e. 11.3 km
%   in the +x direction - and +x is the trailing direction, so the chaser has
%   indeed fallen behind. Reading +x as "ahead" is the classic trap; the
%   audit pins the convention down empirically instead (see below).
%
%   WHY THIS CONVENTION. Measuring V-bar range positive behind the target is
%   the operational habit: a "50 m V-bar hold" is 50 m astern, and the forced
%   approach then walks x from +50 m down to 0 at the port. It also makes
%   TESTS/AUDIT_REFERENCE reproduce an independent implementation of the same
%   mission: fed the reference injection error, TWO_IMPULSE_HOLD returns
%   |dV1| = 1.071 m/s and dV_hold = 1.419 m/s against that write-up's 1.1 and
%   1.4 m/s. The mirrored convention, Phi(t,-n), returns 1.023 and 1.277 and
%   does not reproduce it. See tests/test_hcw_stm_identity.m and
%   results/AUDIT_REPORT.md.

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
