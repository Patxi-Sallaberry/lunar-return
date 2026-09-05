function F = scan_cr3bp_family(x0_LM, x0_MS, p0, C, opts)
%SCAN_CR3BP_FAMILY  Map the zero-miss family instead of reporting one point.
%
%   F = SCAN_CR3BP_FAMILY(x0_LM, x0_MS, p0, C, opts)
%
%   The planar shooting problem has three decision variables and only two
%   independent miss components, so the zero-miss set is a CURVE, not a point.
%   Two implementations that both converge can therefore report different
%   delta-v and different time of flight and both be right. Quoting "the" CR3BP
%   correction hides that.
%
%   This scans time of flight over a window, re-optimising the two impulse
%   components at each fixed tf, and returns every member that closes the
%   rendezvous below the miss tolerance. The caller then quotes the family:
%   the cheapest member, the one closest to the two-body time of flight, and
%   whichever member sits near an externally reported tf.
%
%   opts: .window (default 40 s), .nPts (9), .maxEval (60), .missTol (1 m)

if nargin < 5, opts = struct(); end
win     = getf(opts, 'window', 40);
nPts    = getf(opts, 'nPts', 9);
maxEval = getf(opts, 'maxEval', 60);
missTol = getf(opts, 'missTol', 1e-3);          % km, i.e. 1 m

mu   = C.muCR3BP;
ode  = odeset('RelTol', 1e-11, 'AbsTol', 1e-11);
fo   = optimset('Display','off','MaxFunEvals',maxEval,'MaxIter',maxEval, ...
                'TolX',1e-13,'TolFun',1e-12);

tof0_s = p0(3) * C.TU;
% The externally reported member sits at dTOF = +17.1 s, so put a grid point
% exactly there instead of quoting the nearest neighbour and calling it close.
dtf    = unique([linspace(-win, win, nPts), 17.1]);
tf_s   = tof0_s + dtf;
nPts   = numel(tf_s);

F.tof_s   = tf_s;
F.dV1     = nan(1, nPts);
F.dV2     = nan(1, nPts);
F.dVtot   = nan(1, nPts);
F.miss_km = nan(1, nPts);

% `tof` is shared with the nested cost function below; MATLAB does not allow a
% nested definition inside the loop body, so the loop rebinds it instead.
tof = p0(3);
    function m = cost(d)
        xL = x0_LM; xL(4:5) = xL(4:5) + d(:);
        [~, XL] = ode45(@(t,x) cr3bp_eom(t,x,mu), [0 tof], xL, ode);
        [~, XM] = ode45(@(t,x) cr3bp_eom(t,x,mu), [0 tof], x0_MS, ode);
        m = norm(XL(end,1:3) - XM(end,1:3)) * C.LU;
    end

dv = p0(1:2);                                    % warm start, walks along tf
for k = 1:nPts
    tof = tf_s(k) / C.TU;
    dv = fminsearch(@cost, dv, fo);
    if cost(dv) > missTol
        dv = fminsearch(@cost, dv, fo);          % one restart, same budget
    end

    xL = x0_LM; xL(4:5) = xL(4:5) + dv(:);
    [~, XL] = ode45(@(t,x) cr3bp_eom(t,x,mu), [0 tof], xL, ode);
    [~, XM] = ode45(@(t,x) cr3bp_eom(t,x,mu), [0 tof], x0_MS, ode);

    F.miss_km(k) = norm(XL(end,1:3) - XM(end,1:3)) * C.LU;
    F.dV1(k)     = norm([dv(:); 0]) * C.VU;
    F.dV2(k)     = norm(XM(end,4:6) - XL(end,4:6)) * C.VU;
    F.dVtot(k)   = F.dV1(k) + F.dV2(k);
end

% ------------------------------------------------- pick the three members ---
good = F.miss_km <= missTol;
F.nClosed = sum(good);
F.tof_ref_s = tof0_s;

F.members = struct('label', {}, 'tof_s', {}, 'dtof_s', {}, ...
                   'dVtot', {}, 'miss_m', {});

if any(good)
    idx = find(good);
    [~, j] = min(F.dVtot(idx));            F.members(1) = mk('minimum delta-v', idx(j), F, tof0_s);
    [~, j] = min(abs(F.tof_s(idx) - tof0_s)); F.members(2) = mk('minimum |dTOF|', idx(j), F, tof0_s);
    [~, j] = min(abs(F.tof_s(idx) - (tof0_s + 17.1)));
    F.members(3) = mk('reference-like dTOF', idx(j), F, tof0_s);
    % Width of the family: how much the budget moves across the scanned window.
    F.spread_mms = (max(F.dVtot(idx)) - min(F.dVtot(idx))) * 1e6;
end
end

% ------------------------------------------------------------------ helpers --
function m = mk(label, k, F, tof0)
m = struct('label', label, 'tof_s', F.tof_s(k), 'dtof_s', F.tof_s(k) - tof0, ...
           'dVtot', F.dVtot(k), 'miss_m', F.miss_km(k) * 1e3);
end

function v = getf(s, f, d)
if isfield(s, f) && ~isempty(s.(f)), v = s.(f); else, v = d; end
end
