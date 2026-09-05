function h = fading_trail(ax, color, opts)
%FADING_TRAIL  A motion trail that fades out behind a moving object.
%
%   h = FADING_TRAIL(ax, color)
%   h = FADING_TRAIL(ax, color, opts)  with fields
%       nSeg     number of alpha steps in the tail   (default 10)
%       tail     tail length in samples              (default 60)
%       lw       line width of the brightest segment (default 3)
%       ghost    alpha of the full-history line      (default 0.13)
%       is3D     true for plot3                      (default false)
%
%   A single line at constant alpha reads as a diagram; a tail that fades tells
%   the eye which way the object is going and how fast, which is the whole job
%   of a motion graphic. Implemented as a small stack of line objects with
%   increasing alpha rather than per-vertex alpha, because that renders
%   identically on every MATLAB release and every renderer.
%
%   Pair with UPDATE_TRAIL, which only rewrites XData/YData.

if nargin < 3, opts = struct(); end
h.nSeg  = getf(opts, 'nSeg', 10);
h.tail  = getf(opts, 'tail', 60);
h.is3D  = getf(opts, 'is3D', false);
lw      = getf(opts, 'lw', 3);
ghostA  = getf(opts, 'ghost', 0.13);

if h.is3D
    h.ghost = plot3(ax, NaN, NaN, NaN, '-', 'Color', [color ghostA], 'LineWidth', lw*0.55);
else
    h.ghost = plot(ax, NaN, NaN, '-', 'Color', [color ghostA], 'LineWidth', lw*0.55);
end

h.seg = gobjects(1, h.nSeg);
for k = 1:h.nSeg
    f = k / h.nSeg;
    a = 0.07 + 0.93 * f^1.7;              % perceptually closer to a linear fade
    w = lw * (0.40 + 0.60 * f);
    if h.is3D
        h.seg(k) = plot3(ax, NaN, NaN, NaN, '-', 'Color', [color a], 'LineWidth', w);
    else
        h.seg(k) = plot(ax, NaN, NaN, '-', 'Color', [color a], 'LineWidth', w);
    end
end
end

function v = getf(s, f, d)
if isfield(s, f) && ~isempty(s.(f)), v = s.(f); else, v = d; end
end
