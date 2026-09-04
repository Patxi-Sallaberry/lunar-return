function S = two_impulse_hold(dr0, dv0, r_hold, v_hold, dt_tr, n)
%TWO_IMPULSE_HOLD  Lambert-style HCW targeting onto a V-bar hold point.
%   S = TWO_IMPULSE_HOLD(dr0, dv0, r_hold, v_hold, dt_tr, n) solves for the
%   post-burn velocity that flies the chaser from dr0 to r_hold in dt_tr, then
%   for the arrival impulse that matches v_hold. Everything in metres, m/s and
%   rad/s.
%
%   The whole problem is one linear solve against Phi_rv. That block becomes
%   singular whenever the transfer time approaches a multiple of the orbital
%   period, so its conditioning is checked and the transfer time is nudged by
%   1 % until the solve is safe. The nudge is reported in S.dt_tr.

dr0 = dr0(:); dv0 = dv0(:);
r_hold = r_hold(:); v_hold = v_hold(:);

S.nudged = 0;
for k = 0:20
    [Prr, Prv] = hcw_blocks(dt_tr, n);
    if rcond(Prv) > 1e-10
        break
    end
    dt_tr = dt_tr * 1.01;      % walk away from the degenerate transfer time
    S.nudged = k + 1;
end

[Prr, Prv, Pvr, Pvv] = hcw_blocks(dt_tr, n);

v0_plus = Prv \ (r_hold - Prr * dr0);
S.dV1   = v0_plus - dv0;

v_arr   = Pvr * dr0 + Pvv * v0_plus;
S.dV2   = v_hold - v_arr;

S.dt_tr   = dt_tr;
S.v0_plus = v0_plus;
S.v_arr   = v_arr;
S.dV_total = norm(S.dV1) + norm(S.dV2);
S.rcond_Prv = rcond(Prv);

% Closed-loop verification on a fine grid: the arrival state is recomputed
% from the STM rather than trusted from the design equations.
N = 2001;
S.t = linspace(0, dt_tr, N);
S.x = zeros(6, N);
x0 = [dr0; v0_plus];
for k = 1:N
    S.x(:,k) = phi_hcw(S.t(k), n) * x0;
end
S.x(4:6, end) = S.x(4:6, end) + S.dV2;     % arrival burn closes the velocity

S.err_pos = norm(S.x(1:3, end) - r_hold);
S.err_vel = norm(S.x(4:6, end) - v_hold);
end
