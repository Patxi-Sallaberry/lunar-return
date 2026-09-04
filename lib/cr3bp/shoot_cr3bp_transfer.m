function S = shoot_cr3bp_transfer(x0_LM, x0_MS, p0, C)
%SHOOT_CR3BP_TRANSFER  Single-shooting rendezvous solve in the CR3BP.
%
%   S = SHOOT_CR3BP_TRANSFER(x0_LM, x0_MS, p0, C) takes the pre-burn synodic
%   states of the lunar module and the mothership (6x1, non-dimensional) and
%   the decision-vector guess p0 = [dvx; dvy; tof] (synodic, non-dimensional).
%   It returns the converged departure impulse, time of flight, arrival
%   impulse and both propagated arcs.
%
%   Cost = miss distance in km + a very small regularisation that pulls the
%   solution towards the two-body guess. The regularisation matters: with a
%   planar problem there are only two independent miss components but three
%   decision variables, so the zero-miss set is a curve, not a point. Without
%   it fminsearch wanders along that curve and the reported "CR3BP correction"
%   would be an arbitrary member of a family instead of the smallest one.

mu   = C.muCR3BP;
opts = odeset('RelTol', 1e-12, 'AbsTol', 1e-12);
wReg = 1e-3;                 % km per unit relative deviation from the guess
p0   = p0(:);
sc   = max(abs(p0), 1e-6);   % scale for the regularisation only

    function [miss_km, tLM, XLM, tMS, XMS] = fly(p)
        tof = p(3);
        if tof <= 0
            miss_km = 1e6; tLM = 0; XLM = x0_LM.'; tMS = 0; XMS = x0_MS.';
            return
        end
        xLM = x0_LM;
        xLM(4:5) = xLM(4:5) + p(1:2);
        [tLM, XLM] = ode45(@(t,x) cr3bp_eom(t, x, mu), [0 tof], xLM, opts);
        [tMS, XMS] = ode45(@(t,x) cr3bp_eom(t, x, mu), [0 tof], x0_MS, opts);
        miss_km = norm(XLM(end,1:3) - XMS(end,1:3)) * C.LU;
    end

    function J = cost(p)
        J = fly(p) + wReg * norm((p(:) - p0) ./ sc);
    end

fopts = optimset('Display', 'off', 'MaxFunEvals', 2000, 'MaxIter', 2000, ...
                 'TolX', 1e-13, 'TolFun', 1e-11);

[p, ~, flag] = fminsearch(@cost, p0, fopts);
S.restarted = false;

% One restart from the incumbent: fminsearch on a nearly flat valley often
% stops on the simplex size rather than on the function value.
[missTmp, ~, ~, ~, ~] = fly(p);
if missTmp > 0.1 || flag ~= 1
    [p, ~, flag] = fminsearch(@cost, p, fopts);
    S.restarted = true;
end

[S.miss_km, S.tLM, S.XLM, S.tMS, S.XMS] = fly(p);

S.p        = p;
S.exitflag = flag;
S.tof_TU   = p(3);
S.tof_s    = p(3) * C.TU;
S.dV1_vec  = [p(1); p(2); 0] * C.VU;              % km/s, synodic components
S.dV1      = norm(S.dV1_vec);

% Arrival impulse: velocity difference at a common point, so its magnitude is
% the same in the rotating and the inertial frame.
S.dV2_vec  = (S.XMS(end,4:6) - S.XLM(end,4:6)).' * C.VU;
S.dV2      = norm(S.dV2_vec);
S.dVtot    = S.dV1 + S.dV2;
end
