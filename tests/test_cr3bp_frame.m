function [ok, msg] = test_cr3bp_frame(C)
%TEST_CR3BP_FRAME  Sanity of the MCI <-> synodic conversion.
%
%   1. A body sitting at the Moon's centre with zero inertial velocity must
%      have exactly zero synodic velocity: in the rotating frame the Moon
%      does not move. This is the check that catches a missing or duplicated
%      (1-mu) offset.
%   2. The Earth must land at x = -mu.
%   3. The conversion must round-trip.

alpha = 0.7351;                        % arbitrary epoch angle
mu = C.muCR3BP;

[rs, vs] = moon_inertial_to_synodic([0;0;0], [0;0;0], alpha, C);
e1 = norm(vs);
e2 = norm(rs - [1-mu; 0; 0]);

% Earth sits opposite the synodic +x direction, at MCI longitude alpha - pi.
rE = C.dEM * [cos(alpha - pi); sin(alpha - pi); 0];
[rEs, ~] = moon_inertial_to_synodic(rE, [0;0;0], alpha, C);
e3 = norm(rEs - [-mu; 0; 0]);

r0 = [1500; -900; 0];
v0 = [0.4; 1.5; 0];
[a, b] = moon_inertial_to_synodic(r0, v0, alpha, C);
[c, d] = synodic_to_moon_centered(a, b, alpha, C);
e4 = norm(c - r0) + norm(d - v0);

ok = (e1 < 1e-14) && (e2 < 1e-14) && (e3 < 1e-12) && (e4 < 1e-9);
msg = sprintf('moon-at-rest |v_syn| = %.1e, Moon at 1-mu %.1e, Earth at -mu %.1e, round trip %.1e', ...
              e1, e2, e3, e4);
end
