function h = draw_moon(ax, R, center)
%DRAW_MOON  Lunar disk with a terminator, craters and a limb highlight.
%   h = DRAW_MOON(ax, R)          centred on the origin of a 2-D axes
%   h = DRAW_MOON(ax, R, center)  offset
%
%   Built entirely from patches: a base disk, a two-tone terminator lit from
%   +x, sixteen craters and a thin bright limb arc on the lit side. No imagery
%   is downloaded, so there is no licence attached to any frame of the video.
%
%   Crater placement uses a golden-angle spiral rather than rand(). The Moon is
%   therefore identical on every run WITHOUT touching the global RNG stream,
%   which matters because Part 2 draws its injection error from that stream and
%   must stay reproducible no matter how many figures were rendered first.

if nargin < 3, center = [0; 0]; end
S = style();
cx = center(1); cy = center(2);
th = linspace(0, 2*pi, 361);

% Base disk.
h.disk = patch(ax, cx + R*cos(th), cy + R*sin(th), S.moonFace, ...
               'EdgeColor', S.moonEdge, 'LineWidth', 1.2, 'FaceAlpha', 0.97);

% Terminator, lit from +x: two nested crescents of decreasing brightness,
% each clipped to the disk by construction.
for k = 1:2
    shift = [0.30 0.62] * R;
    tone  = [1.10 1.20];
    alpha = [0.30 0.26];
    hk = patch(ax, cx + R*cos(th) + shift(k), cy + R*sin(th), ...
               min(S.moonFace*tone(k), 1), 'EdgeColor', 'none', 'FaceAlpha', alpha(k));
    clip_to_disk(hk, cx, cy, R);
    h.lit(k) = hk; %#ok<AGROW>
end

% Craters.
ga = pi * (3 - sqrt(5));
nC = 16;
h.craters = gobjects(1, nC);
for k = 1:nC
    rr = R * 0.87 * sqrt(k / (nC + 1));
    aa = k * ga;
    ccx = cx + rr*cos(aa);
    ccy = cy + rr*sin(aa);
    cr  = R * (0.040 + 0.060 * mod(k * 0.618, 1));
    shade = 0.90 + 0.10 * mod(k * 0.382, 1);
    h.craters(k) = patch(ax, ccx + cr*cos(th), ccy + cr*sin(th), S.crater*shade, ...
                         'EdgeColor', S.moonEdge, 'LineWidth', 0.5, 'FaceAlpha', 0.72);
end

% Thin limb highlight on the lit side.
tl = linspace(-1.05, 1.05, 120);
h.limb = plot(ax, cx + R*0.995*cos(tl), cy + R*0.995*sin(tl), '-', ...
              'Color', [min(S.moonFace*1.35, 1) 0.85], 'LineWidth', 2.0);

h.label = text(ax, cx, cy - 0.5*R, 'MOON', ...
               'Color', S.moonEdge*0.7, 'FontName', S.font, ...
               'FontSize', S.fsSmall, 'FontWeight', 'bold', ...
               'HorizontalAlignment', 'center');
end

% ------------------------------------------------------------------ helpers --
function clip_to_disk(hp, cx, cy, R)
%CLIP_TO_DISK  Intersect a patch with the lunar disk by trimming its vertices.
%   Cheaper and more portable than a real clipping path: the crescent is only
%   ever a shifted circle, so pulling stray vertices back onto the limb gives
%   exactly the right silhouette.
x = get(hp, 'XData');
y = get(hp, 'YData');
d = hypot(x - cx, y - cy);
out = d > R;
if any(out)
    s = R ./ d(out);
    x(out) = cx + (x(out) - cx) .* s;
    y(out) = cy + (y(out) - cy) .* s;
    set(hp, 'XData', x, 'YData', y);
end
end
