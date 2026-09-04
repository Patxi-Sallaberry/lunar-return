function H = hohmann_design(R1, R2, mu)
%HOHMANN_DESIGN  Tangential two-impulse transfer between coplanar circles.
%   H = HOHMANN_DESIGN(R1, R2, mu) returns a struct with the transfer ellipse
%   geometry, both impulses and the time of flight. All inputs in km and
%   km^3/s^2; speeds come back in km/s, dV also in m/s for convenience.
%
%   Ascending transfer (R2 > R1): both burns are accelerations, dV1 at the
%   periapsis of the ellipse (= R1) and dV2 at the apoapsis (= R2).

H.R1 = R1;
H.R2 = R2;
H.a  = 0.5 * (R1 + R2);
H.e  = abs(R2 - R1) / (R2 + R1);
H.p  = H.a * (1 - H.e^2);

H.vc1 = sqrt(mu / R1);
H.vc2 = sqrt(mu / R2);
H.vpe = sqrt(mu * (2/R1 - 1/H.a));   % speed on the ellipse at radius R1
H.vap = sqrt(mu * (2/R2 - 1/H.a));   % speed on the ellipse at radius R2

H.dV1 = H.vpe - H.vc1;
H.dV2 = H.vc2 - H.vap;
H.dVtot = abs(H.dV1) + abs(H.dV2);

H.dV1_ms   = H.dV1   * 1e3;
H.dV2_ms   = H.dV2   * 1e3;
H.dVtot_ms = H.dVtot * 1e3;

H.nH     = sqrt(mu / H.a^3);
H.Tell   = 2*pi / H.nH;
H.dt_tof = 0.5 * H.Tell;

% Specific energy and angular momentum of each leg, used by the constants-of-
% motion figure as the analytical reference plateaus.
H.eps_in  = -mu / (2*R1);
H.eps_tr  = -mu / (2*H.a);
H.eps_out = -mu / (2*R2);
H.h_in    = sqrt(mu * R1);
H.h_tr    = sqrt(mu * H.p);
H.h_out   = sqrt(mu * R2);
end
