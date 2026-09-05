function R = mc_hold(C, nDraw, seed)
%MC_HOLD  Monte Carlo over the injection error, state transition matrix only.
%
%   R = MC_HOLD(C)              20 draws, seed 20240 (NOT the official 42)
%   R = MC_HOLD(C, nDraw, seed)
%
%   The headline numbers in the report come from one draw of rng(42). That is
%   reproducible but it is a single sample, and "one random draw" was an honest
%   limitation in the pass-2 report. This routine removes it cheaply: the same
%   error law, the same targeting, propagated with the STM only, so 20 draws
%   cost milliseconds instead of minutes.
%
%   The official draw is deliberately NOT re-seeded here. rng(42) stays exactly
%   where it is in part2; this function uses its own stream so that running or
%   not running the Monte Carlo cannot change the reported headline.
%
%   Returns median, 5th and 95th percentile of the hold and docking delta-v.

if nargin < 2 || isempty(nDraw), nDraw = 20; end
if nargin < 3 || isempty(seed),  seed  = 20240; end

n = C.n2;
s = RandStream('twister', 'Seed', seed);   % private stream, global rng untouched

dvHold = zeros(1, nDraw);
dvDock = zeros(1, nDraw);
drift  = zeros(1, nDraw);

for k = 1:nDraw
    ur = randn(s, 3, 1); ur = ur / norm(ur);
    uv = randn(s, 3, 1); uv = uv / norm(uv);
    dr0 = ur * (C.errPosRange(1) + diff(C.errPosRange) * rand(s));
    dv0 = uv * (C.errVelRange(1) + diff(C.errVelRange) * rand(s));

    % Free drift over the same horizon as part 2, STM only.
    xEnd = phi_hcw(C.nDriftOrbits * C.T2, n) * [dr0; dv0];
    drift(k) = norm(xEnd(1:3)) / 1e3;                       % km

    H = two_impulse_hold(dr0, dv0, C.r_hold, C.v_hold, C.dt_tr, n);
    D = forced_vbar_docking(C.r_hold, C.v_hold, C.r_hold, C.N_legs, C.T_dock, n);

    dvHold(k) = H.dV_total;
    dvDock(k) = D.dV_total;
end

R.nDraw    = nDraw;
R.seed     = seed;
R.dvHold   = dvHold;
R.dvDock   = dvDock;
R.drift_km = drift;

R.hold_p05 = prctile_local(dvHold, 5);
R.hold_p50 = prctile_local(dvHold, 50);
R.hold_p95 = prctile_local(dvHold, 95);
R.dock_p50 = prctile_local(dvDock, 50);
R.dock_p95 = prctile_local(dvDock, 95);
R.drift_p50 = prctile_local(drift, 50);
R.drift_p95 = prctile_local(drift, 95);
end

function v = prctile_local(x, p)
%PRCTILE_LOCAL  Linear-interpolation percentile. Statistics Toolbox is not a
%   dependency of this repository and is not going to become one for this.
x = sort(x(:));
m = numel(x);
if m == 1, v = x; return, end
pos = (p/100) * m + 0.5;                 % midpoint convention, as prctile
pos = max(1, min(m, pos));
lo = floor(pos); hi = ceil(pos);
if lo == hi
    v = x(lo);
else
    v = x(lo) + (pos - lo) * (x(hi) - x(lo));
end
end
