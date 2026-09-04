function h = draw_moon(ax, R, center)
%DRAW_MOON  Filled lunar disk with craters, drawn from scratch.
%   h = DRAW_MOON(ax, R) draws a disk of radius R centred on the origin of a
%   2-D axes, plus a terminator shading and eleven craters.
%   h = DRAW_MOON(ax, R, center) offsets it.
%
%   Crater placement uses a golden-angle spiral rather than rand(), so the
%   Moon looks identical on every run WITHOUT touching the global RNG state.
%   Part 2 draws its injection error from that same stream and must stay
%   reproducible no matter how many figures were drawn first.
%
%   No external imagery: everything here is patches and lines.

if nargin < 3, center = [0; 0]; end
S = style();

th = linspace(0, 2*pi, 361);
h.disk = patch(ax, center(1) + R*cos(th), center(2) + R*sin(th), S.moonFace, ...
               'EdgeColor', S.moonEdge, 'LineWidth', 1.2, 'FaceAlpha', 0.95);

% Lit side: a lighter inset disk offset towards +x. Inset rather than
% outset so it never paints a dark halo outside the limb.
h.limb = patch(ax, center(1) + 0.90*R*cos(th) + 0.07*R, ...
                   center(2) + 0.90*R*sin(th) + 0.03*R, ...
                   min(S.moonFace*1.15, 1), 'EdgeColor','none', 'FaceAlpha', 0.45);

ga = pi * (3 - sqrt(5));            % golden angle
nC = 11;
h.craters = gobjects(1, nC);
for k = 1:nC
    rr = R * 0.86 * sqrt(k / (nC + 1));
    aa = k * ga;
    cx = center(1) + rr * cos(aa);
    cy = center(2) + rr * sin(aa);
    cr = R * (0.055 + 0.075 * mod(k * 0.618, 1));
    h.craters(k) = patch(ax, cx + cr*cos(th), cy + cr*sin(th), S.crater, ...
                         'EdgeColor', S.moonEdge, 'LineWidth', 0.6, ...
                         'FaceAlpha', 0.85);
end

h.label = text(ax, center(1), center(2) - 0.45*R, 'MOON', ...
               'Color', [0.15 0.16 0.18], 'FontName', S.font, ...
               'FontSize', S.fsSmall, 'FontWeight', 'bold', ...
               'HorizontalAlignment', 'center');
end
