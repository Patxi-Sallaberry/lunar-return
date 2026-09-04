function [ok, msg] = test_hohmann_numbers(C)
%TEST_HOHMANN_NUMBERS  Hohmann and phasing scalars against the design targets.
%   Relative tolerance 1e-3 on every speed and impulse, absolute 1 s on the
%   phasing wait.

H = hohmann_design(C.R1, C.R2, C.muMoon);
P = phasing_wait(C.n1, C.n2, H.dt_tof, C.phi0);

checks = { 'vc1',    H.vc1,      1.6335
           'vc2',    H.vc2,      1.5145
           'vpe',    H.vpe,      1.6940
           'vap',    H.vap,      1.4563
           'dV1',    H.dV1_ms,     60.52
           'dV2',    H.dV2_ms,     58.28
           'dVtot',  H.dVtot_ms,  118.80
           'a',      H.a,        1987.4
           'e',      H.e,        0.0755
           'Tell',   H.Tell,     7950.34
           'dt_tof', H.dt_tof,   3975.17 };

ok = true;
bad = {};
for k = 1:size(checks,1)
    rel = abs(checks{k,2} - checks{k,3}) / abs(checks{k,3});
    if rel > 1e-3
        ok = false;
        bad{end+1} = sprintf('%s=%.6g (target %.6g, rel %.2e)', ...
                             checks{k,1}, checks{k,2}, checks{k,3}, rel); %#ok<AGROW>
    end
end

dtw = abs(P.t_wait - 33988);
if dtw > 1
    ok = false;
    bad{end+1} = sprintf('t_wait=%.2f s (target 33988 +-1)', P.t_wait);
end

if ok
    msg = sprintf('11 scalars within 1e-3, t_wait = %.1f s (%.2f s from target)', ...
                  P.t_wait, dtw);
else
    msg = strjoin(bad, '; ');
end
end
