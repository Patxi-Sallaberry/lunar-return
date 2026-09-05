function R = j2_secular_rates(C, a, e, i_rad)
%J2_SECULAR_RATES  Closed-form secular element rates under J2 (Vallado).
%
%   R = J2_SECULAR_RATES(C, a, e, i)   angles in radians, a in km.
%
%       n_bar = sqrt(mu/a^3),  p = a(1-e^2),  k = (3/4) n_bar J2 (R_M/p)^2
%       Omegadot = -2k cos i
%       omegadot =  k (4 - 5 sin^2 i)
%       Mdot     =  n_bar + k sqrt(1-e^2) (2 - 3 sin^2 i)
%
%   On the equatorial circular orbits used here (i = 0, e = 0) the node and the
%   argument of periapsis are individually undefined, but their sum with the
%   mean anomaly is not: the observable is the mean-longitude rate
%
%       lambdadot = Omegadot + omegadot + Mdot = n_bar [1 + 3 J2 (R_M/a)^2].
%
%   This replaces the hand-waving "a stiffer central field shifts n by
%   dn/n = (1/2) dmu_eff/mu" argument, which gives (3/4) J2 (R/a)^2 and is a
%   factor of four too small because it only captures the radial stiffening and
%   drops the periapsis and node contributions.

n_bar = sqrt(C.muMoon / a^3);
p     = a * (1 - e^2);
k     = 0.75 * n_bar * C.J2Moon * (C.RMoon / p)^2;

R.n_bar     = n_bar;
R.Omegadot  = -2 * k * cos(i_rad);
R.omegadot  =  k * (4 - 5*sin(i_rad)^2);
R.Mdot      =  n_bar + k * sqrt(1 - e^2) * (2 - 3*sin(i_rad)^2);
R.lambdadot = R.Omegadot + R.omegadot + R.Mdot;

% Fractional excess over the Keplerian rate; equals 3*J2*(R/a)^2 when i = e = 0.
R.excess    = R.lambdadot / n_bar - 1;
R.excess_eq = 3 * C.J2Moon * (C.RMoon / a)^2;
end
