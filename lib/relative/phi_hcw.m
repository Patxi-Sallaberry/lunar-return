function Phi = phi_hcw(t, n)
%PHI_HCW  State transition matrix of the Hill-Clohessy-Wiltshire equations.
%
%   Phi = PHI_HCW(t, n)   scalar t  -> 6x6
%   Phi = PHI_HCW(t, n)   1xN row t -> 6x6xN, no loop
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
%   THIS IS NOT FEHSE'S FRAME. Fehse and the usual rendezvous literature put
%   +V-bar ahead of the target; here it is astern. Every Coriolis sign is
%   therefore flipped with respect to that literature, and a state expressed
%   here is converted to a Fehse implementation by negating x and xdot. The
%   convention is not interchangeable, and the report says so in a boxed note
%   rather than leaving a reader to discover it.
%
%   WHY THIS CONVENTION. Two independent reasons, both tested in
%   tests/test_hcw_convention.m:
%     1. Physical. Released 100 m radially outward at zero relative velocity,
%        the chaser is higher, slower, and must fall behind. This STM gives
%        x = +11.3 km after three orbits, and +x is astern, so it has indeed
%        fallen behind. Reading +x as "ahead" is the classic trap.
%     2. Empirical. Fed the reference injection error of an independent
%        implementation of the same mission, TWO_IMPULSE_HOLD returns
%        dV_hold = 1.419 m/s against that write-up's 1.4 m/s. Reading the same
%        physical state in the Fehse frame instead gives 1.236 m/s and does not
%        reproduce it. The reference geometry uses this frame.
%
%   Operationally it is also the natural choice here: a "50 m V-bar hold" is
%   50 m astern, and the forced approach walks x from +50 m down to 0.

t = t(:).';                 % row
N = numel(t);
tau = n * t;
s = sin(tau);
c = cos(tau);
o = ones(1, N);
z = zeros(1, N);

% Built by page so the whole stack is one reshape, no loop over samples.
Phi = zeros(6, 6, N);
Phi(1,1,:) = o;         Phi(1,3,:) = 6*(tau - s);   Phi(1,4,:) = (4*s - 3*tau)/n;
                        Phi(1,6,:) = 2*(1 - c)/n;
Phi(2,2,:) = c;         Phi(2,5,:) = s/n;
Phi(3,3,:) = 4 - 3*c;   Phi(3,4,:) = 2*(c - 1)/n;   Phi(3,6,:) = s/n;
Phi(4,3,:) = 6*n*(1-c); Phi(4,4,:) = 4*c - 3;       Phi(4,6,:) = 2*s;
Phi(5,2,:) = -n*s;      Phi(5,5,:) = c;
Phi(6,3,:) = 3*n*s;     Phi(6,4,:) = -2*s;          Phi(6,6,:) = c;
Phi(1,2,:) = z;         % explicit, so the zero pattern is readable above

if N == 1
    Phi = Phi(:,:,1);   % scalar t keeps the historical 6x6 return
end
end
