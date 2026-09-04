function [r_km, v_kms] = synodic_to_moon_centered(r_syn, v_syn, alpha, C)
%SYNODIC_TO_MOON_CENTERED  Exact inverse of MOON_INERTIAL_TO_SYNODIC.
%   [r_km, v_kms] = SYNODIC_TO_MOON_CENTERED(r_syn, v_syn, alpha, C) with
%   alpha the MCI longitude of the synodic +x axis at that instant.

mu = C.muCR3BP;
c = cos(alpha); s = sin(alpha);
Rout = [ c -s  0;  s  c  0; 0 0 1];     % = Rz(alpha), Earth-Moon axes -> MCI

r_km  = Rout * (r_syn(:) - [1-mu; 0; 0]) * C.LU;
v_kms = Rout * (v_syn(:) + cross([0;0;1], r_syn(:)) - [0; 1-mu; 0]) * C.VU;
end
