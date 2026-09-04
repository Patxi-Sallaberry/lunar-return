function [r, v] = coe2rv(a, e, i_deg, RAAN_deg, argp_deg, nu_deg, mu)
%COE2RV  Cartesian state from classical orbital elements.
%   [r, v] = COE2RV(a, e, i, RAAN, argp, nu, mu) with angles in degrees,
%   a in km and mu in km^3/s^2. Elliptic and circular orbits only.
%
%   Used to round-trip RV2COE in the unit tests and to seed the geometry
%   figures with an ellipse sampled in true anomaly.

i    = deg2rad(i_deg);
RAAN = deg2rad(RAAN_deg);
argp = deg2rad(argp_deg);
nu   = deg2rad(nu_deg(:).');

p  = a * (1 - e^2);
rn = p ./ (1 + e * cos(nu));

r_pf = [rn .* cos(nu); rn .* sin(nu); zeros(size(nu))];
v_pf = sqrt(mu/p) * [-sin(nu); e + cos(nu); zeros(size(nu))];

cO = cos(RAAN); sO = sin(RAAN);
cw = cos(argp); sw = sin(argp);
ci = cos(i);    si = sin(i);

R = [ cO*cw - sO*sw*ci, -cO*sw - sO*cw*ci,  sO*si;
      sO*cw + cO*sw*ci, -sO*sw + cO*cw*ci, -cO*si;
      sw*si,             cw*si,             ci   ];

r = R * r_pf;
v = R * v_pf;
end
