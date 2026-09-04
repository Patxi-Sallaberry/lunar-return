function [r_syn, v_syn] = moon_inertial_to_synodic(r_km, v_kms, alpha, C)
%MOON_INERTIAL_TO_SYNODIC  MCI state -> non-dimensional synodic CR3BP state.
%
%   [r_syn, v_syn] = MOON_INERTIAL_TO_SYNODIC(r_km, v_kms, alpha, C) where
%   alpha is the MCI longitude of the synodic +x axis at that instant, i.e.
%   the Earth-to-Moon direction. With the Part 3 Earth ephemeris
%   theta_E(t) = nEM*t (Earth on +x at t = 0) the Moon-to-Earth direction is
%   theta_E, so the Earth-to-Moon direction is alpha = theta_E + pi.
%
%   Three things happen, in order:
%     1. rotate MCI components into the frame whose +x is the Earth-Moon line
%     2. translate the origin from the Moon to the barycentre and scale by LU
%     3. subtract the frame rotation, omega x r, and add the Moon's own
%        inertial velocity, which in these units is [0; 1-mu; 0]
%
%   Consistency check (exercised by the unit tests): a spacecraft sitting at
%   the Moon's centre with zero MCI velocity must come out with exactly zero
%   synodic velocity, because in the rotating frame the Moon does not move.

mu = C.muCR3BP;
c = cos(alpha); s = sin(alpha);
Rin = [ c  s  0; -s  c  0; 0 0 1];      % = Rz(-alpha), MCI -> Earth-Moon axes

r_syn = Rin * (r_km(:)  / C.LU) + [1-mu; 0; 0];
v_syn = Rin * (v_kms(:) / C.VU) + [0; 1-mu; 0] - cross([0;0;1], r_syn);
end
