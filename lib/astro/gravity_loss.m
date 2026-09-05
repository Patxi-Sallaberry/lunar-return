function T = gravity_loss(C, dV_ms, TW_list)
%GRAVITY_LOSS  First-order finite-burn penalty for a tangential orbit-raising
%   impulse, analytic, no integration.
%
%   T = GRAVITY_LOSS(C, dV_ms, TW_list) with dV in m/s and TW_list a vector of
%   thrust-to-local-weight ratios. Returns a struct array with tb, the arc swept
%   during the burn, and the delta-v penalty.
%
%   Model. A finite tangential burn of duration tb on a circular orbit sweeps
%   an arc dtheta = n*tb while thrusting. Because the thrust direction rotates
%   with the velocity while the desired velocity increment does not, the
%   effective increment is the vector average
%
%       dV_eff / dV = sin(dtheta/2) / (dtheta/2)  ~  1 - dtheta^2/24,
%
%   so the penalty is  loss ~ dV * (n*tb)^2 / 24  (Vallado, finite-burn losses).
%
%   A note on the formula, because it is easy to get wrong. The expression
%   "loss ~ (1/2) n^2 r tb^2" that circulates for this estimate has units of
%   LENGTH, not velocity: it is the free-fall displacement over the burn, and
%   evaluated here it returns 126 km/s, which is nonsense. The sinc form above
%   is dimensionally correct and reproduces the expected millimetres-per-second
%   to few-metres-per-second band.
%
%   For a lunar ascent stage T/W is quoted against LOCAL lunar gravity,
%   g_local = mu/R1^2 = 1.45 m/s^2, not against Earth weight.

g_local = C.muMoon / C.R1^2 * 1e3;        % m/s^2
n       = C.n1;                            % rad/s at the departure orbit

T = struct('TW', {}, 'a_thrust', {}, 'tb', {}, 'arc_deg', {}, ...
           'loss_ms', {}, 'loss_frac', {});

for k = 1:numel(TW_list)
    TW  = TW_list(k);
    at  = TW * g_local;                    % m/s^2
    tb  = dV_ms / at;                      % s
    arc = n * tb;                          % rad swept while thrusting
    loss = dV_ms * arc^2 / 24;             % m/s

    T(k).TW        = TW;
    T(k).a_thrust  = at;
    T(k).tb        = tb;
    T(k).arc_deg   = rad2deg(arc);
    T(k).loss_ms   = loss;
    T(k).loss_frac = loss / dV_ms;
end
end
