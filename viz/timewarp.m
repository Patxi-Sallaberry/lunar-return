function [idx, tSel, segIdx] = timewarp(t, segs, fps)
%TIMEWARP  Map physical time onto screen time, segment by segment.
%   [idx, tSel, segIdx] = TIMEWARP(t, segs, fps)
%
%   segs is a struct array with fields t0, t1 (physical seconds) and screen_s
%   (how long that stretch should last on screen). Each segment is resampled
%   to round(screen_s*fps) frames and the result is a list of indices into t.
%
%   Without this the 9.4 hour phasing coast would occupy 99 % of the clip and
%   the two burns would be invisible. The HUD keeps showing the true mission
%   clock, so the acceleration is legible instead of hidden.

t = t(:).';
idx = [];
tSel = [];
segIdx = [];

for s = 1:numel(segs)
    nF = max(1, round(segs(s).screen_s * fps));
    tq = linspace(segs(s).t0, segs(s).t1, nF);
    ii = interp1(t, 1:numel(t), tq, 'nearest', 'extrap');
    ii = max(1, min(numel(t), round(ii)));
    idx    = [idx, ii];            %#ok<AGROW>
    tSel   = [tSel, tq];           %#ok<AGROW>
    segIdx = [segIdx, s*ones(1,nF)];%#ok<AGROW>
end
end
