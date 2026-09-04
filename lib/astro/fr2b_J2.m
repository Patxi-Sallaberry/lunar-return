function dx = fr2b_J2(~, x, mu, J2, Rb)
%FR2B_J2  Two-body motion plus the J2 zonal harmonic (Cowell formulation).
%   dx = FR2B_J2(t, x, mu, J2, Rb) with x = [r; v] in km, km/s, mu in
%   km^3/s^2 and Rb the body reference radius in km.
%
%   For strictly equatorial orbits (z = 0) the J2 term collapses to a purely
%   radial correction. It does not tilt the plane, but it stiffens the central
%   field by a different amount at each radius, so two coplanar circular
%   orbits accumulate a *relative* along-track phase error. That drift is the
%   quantity Part 3 measures.

r = x(1:3);
v = x(4:6);
rn = norm(r);

k  = 1.5 * J2 * mu * Rb^2 / rn^4;
zr2 = (r(3)/rn)^2;
aJ2 = k * [ (r(1)/rn) * (5*zr2 - 1);
            (r(2)/rn) * (5*zr2 - 1);
            (r(3)/rn) * (5*zr2 - 3) ];

dx = [v; -mu * r / rn^3 + aJ2];
end
