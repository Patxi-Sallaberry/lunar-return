function R = midcourse_correction(C, f, x0_LM, x0_MS, t_wait, tof, dV1, opts)
%MIDCOURSE_CORRECTION  Retarget the transfer against the perturbed mothership.
%
%   R = MIDCOURSE_CORRECTION(C, f, x0_LM, x0_MS, t_wait, tof, dV1, opts)
%
%   f      dynamics handle @(t,x), the SAME Cowell model that produced the miss
%   opts   .t_corr   epoch of the correcting impulse, default t_wait + tof/2
%          .maxEval  fminsearch budget, default 80
%          .dV2_nom  nominal Keplerian arrival impulse [m/s], for the delta
%          .ode      odeset struct
%
%   Why this exists. The report used to price the mid-course as n2*||d||, the
%   Clohessy-Wiltshire cost of cancelling a 15 km offset over a fraction of an
%   orbit. That answers the wrong question: nobody flies a 15 km along-track
%   error as a proximity manoeuvre. This routine computes the real thing,
%   single shooting on a correcting impulse inside the same perturbed model,
%   targeting the perturbed mothership at the nominal arrival epoch.
%
%   The impulse epoch is a parameter and it matters more than anything else in
%   this file. A phase error is corrected by buying a small period change and
%   letting it integrate, so the cost scales roughly as the inverse of the
%   remaining lever arm. Correcting halfway through the 66-minute transfer
%   leaves 33 minutes and is barely cheaper than the naive CW number;
%   correcting during the 9.4-hour phasing coast leaves hours and is an order
%   of magnitude cheaper. SCAN_MIDCOURSE_EPOCH maps that trade.
%
%   Returned:
%     R.dV_mid       magnitude of the correcting impulse [m/s]
%     R.dV_arr       arrival impulse actually required under perturbations
%     R.dV_extra     dV_mid + |dV_arr - dV_arr_nom|, the cost OVER the plan
%     R.miss_before / R.miss_after   [km]

if nargin < 8, opts = struct(); end
t_arr   = t_wait + tof;
% Default epoch is halfway through the MISSION, not halfway through the
% transfer. The 15 km error is accumulated mostly during the 9.4 h phasing
% coast, so the correction belongs there: it leaves a lever arm of hours
% instead of the 33 minutes left by a mid-transfer burn.
t_corr  = getf(opts, 't_corr', 0.5*(t_wait + tof));
maxEval = getf(opts, 'maxEval', 80);
odeOpt  = getf(opts, 'ode', C.odeWork);
nGuess  = getf(opts, 'n', C.n2);

t_corr = min(max(t_corr, 0.02*t_wait), t_arr - 60);   % keep a usable lever arm

% ------------------------------------------------------- nominal perturbed --
[rn, vn] = fly_nominal(f, x0_LM, t_wait, t_arr, dV1, odeOpt, []);
[~, XS]  = ode45(f, [0 t_arr], x0_MS, odeOpt);
r_MS = XS(end,1:3).';
v_MS = XS(end,4:6).';

d0 = rn - r_MS;
R.miss_before = norm(d0);

% ----------------------------------------------------------- initial guess --
% Linear CW map over the remaining arc: the impulse that would null the
% observed offset if the relative motion were linear. Only a starting point.
[~, Prv] = hcw_blocks(t_arr - t_corr, nGuess);
dv_guess = -(Prv \ (d0 * 1e3)) / 1e3;

% ---------------------------------------------------------------- shooting --
nEval = 0;
    function m = cost(dv)
        nEval = nEval + 1;
        rr = fly_nominal(f, x0_LM, t_wait, t_arr, dV1, odeOpt, {t_corr, dv});
        m  = norm(rr - r_MS);
    end

fo = optimset('Display','off','MaxFunEvals',maxEval,'MaxIter',maxEval, ...
              'TolX',1e-14,'TolFun',1e-11);
dv_opt = fminsearch(@cost, dv_guess(1:2), fo);

% One restart from the incumbent. Nelder-Mead on a narrow valley routinely
% stops on simplex size rather than on the function value, and a retarget that
% leaves a 200 m residual is not a retarget.
if cost(dv_opt) > 1e-3                                  % > 1 m
    dv_opt = fminsearch(@cost, dv_opt, fo);
end

[r_fin, v_fin] = fly_nominal(f, x0_LM, t_wait, t_arr, dV1, odeOpt, {t_corr, dv_opt});

R.t_corr     = t_corr;
R.miss_after = norm(r_fin - r_MS);
R.dV_mid     = norm(dv_opt) * 1e3;
R.dV_arr     = norm(v_MS - v_fin) * 1e3;
R.dV_arr_nom = getf(opts, 'dV2_nom', NaN);
R.dV_extra   = R.dV_mid + abs(R.dV_arr - R.dV_arr_nom);
R.nEval      = nEval;
R.dv_vec     = dv_opt(:);
R.lever_s    = t_arr - t_corr;
end

% ------------------------------------------------------------------ helpers --
function [rf, vf] = fly_nominal(f, x0, t_wait, t_arr, dV1, odeOpt, corr)
%FLY_NOMINAL  Coast, tangential departure burn, transfer, with an optional
%   correcting impulse inserted at an arbitrary epoch on either side of the
%   departure burn.
epochs = 0;
if ~isempty(corr), epochs = corr{1}; end

x = x0;
t = 0;

if ~isempty(corr) && epochs < t_wait
    [~, X] = ode45(f, [t epochs], x, odeOpt); x = X(end,:).';
    x(4:5) = x(4:5) + corr{2}(:);
    t = epochs;
end

[~, X] = ode45(f, [t t_wait], x, odeOpt); x = X(end,:).';
x(4:6) = x(4:6) + dV1 * x(4:6)/norm(x(4:6));      % departure burn, perturbed v
t = t_wait;

if ~isempty(corr) && epochs >= t_wait
    [~, X] = ode45(f, [t epochs], x, odeOpt); x = X(end,:).';
    x(4:5) = x(4:5) + corr{2}(:);
    t = epochs;
end

[~, X] = ode45(f, [t t_arr], x, odeOpt);
rf = X(end,1:3).';
vf = X(end,4:6).';
end

function v = getf(s, f, d)
if isfield(s, f) && ~isempty(s.(f)), v = s.(f); else, v = d; end
end
