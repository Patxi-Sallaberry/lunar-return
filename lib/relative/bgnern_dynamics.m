function dx = bgnern_dynamics(~, x, n, R2_m, mu_m)
%BGNERN_DYNAMICS  Exact nonlinear relative motion about a circular chief.
%   dx = BGNERN_DYNAMICS(t, x, n, R2_m, mu_m) integrates the relative state
%   x = [x; y; z; xdot; ydot; zdot] in SI units (metres, m/s) using the same
%   non-standard LVLH axes as PHI_HCW: x along-track, y cross-track, z radial.
%
%   Units: R2_m in metres and mu_m in m^3/s^2. Mixing km into this function is
%   the single most common way to get a plausible-looking but wrong divergence
%   curve, so the caller is required to convert.
%
%   The gravity-gradient difference is written with the classical q/F
%   regularisation instead of the raw difference of two nearly equal inverse
%   cubes; that keeps the right-hand side accurate when rho/R2 ~ 1e-5, which
%   is exactly the regime of close-range operations.

xr = x(1); yr = x(2); zr = x(3);
xd = x(4); yd = x(5); zd = x(6);

rho2 = xr^2 + yr^2 + zr^2;
rc   = sqrt(xr^2 + yr^2 + (R2_m + zr)^2);

q = (rho2 + 2*R2_m*zr) / R2_m^2;
F = q * (2 + q + sqrt(1+q)) / ( (1+q)^(3/2) * (1 + sqrt(1+q)) );

k = mu_m / rc^3;

xdd =  (n^2 - k) * xr + 2*n*zd;
ydd = -k * yr;
zdd = -2*n*xd + (n^2 - k) * zr + (mu_m / R2_m^2) * F;

dx = [xd; yd; zd; xdd; ydd; zdd];
end
