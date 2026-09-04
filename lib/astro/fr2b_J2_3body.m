function dx = fr2b_J2_3body(t, x, C)
%FR2B_J2_3BODY  Moon-centered Cowell dynamics: central + J2 + Earth third body.
%   dx = FR2B_J2_3BODY(t, x, C) with x = [r; v] in km and km/s, t in seconds
%   from the mission epoch, C from MISSION_CONSTANTS.
%
%   The third-body term uses Battin's difference form. The second term (the
%   indirect part) is what keeps the equation Moon-centered: it removes the
%   acceleration of the origin itself. Dropping it is a classic factor-of-two
%   style error that inflates the drift by orders of magnitude.
%
%   The Earth is placed on a circular orbit about the Moon at the synodic rate
%   nEM = sqrt((muMoon + muEarth)/dEM^3), starting on the +x axis at t = 0.

r  = x(1:3);
v  = x(4:6);
rn = norm(r);

% --- J2 (equatorial oblateness) ------------------------------------------
k   = 1.5 * C.J2Moon * C.muMoon * C.RMoon^2 / rn^4;
zr2 = (r(3)/rn)^2;
aJ2 = k * [ (r(1)/rn) * (5*zr2 - 1);
            (r(2)/rn) * (5*zr2 - 1);
            (r(3)/rn) * (5*zr2 - 3) ];

% --- Earth as a third body -----------------------------------------------
th  = C.nEM * t;
rE  = C.dEM * [cos(th); sin(th); 0];
d   = rE - r;
a3B = C.muEarth * ( d / norm(d)^3 - rE / norm(rE)^3 );

dx = [v; -C.muMoon * r / rn^3 + aJ2 + a3B];
end
