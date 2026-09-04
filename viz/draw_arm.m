function h = draw_arm(ax, FK, P, showBus)
%DRAW_ARM  Render the 5R berthing arm in a 3-D axes.
%   h = DRAW_ARM(ax, FK, P) draws each link as a shaded cylinder, joints as
%   spheres and the end-effector frame as a small triad. Pass showBus = false
%   to omit the mothership bus.
%
%   The returned handle struct is designed to be fed back to UPDATE_ARM so the
%   video loop rewrites vertex data instead of rebuilding the scene.

if nargin < 4, showBus = true; end
S = style();

pts = link_points(FK, P);

h.link = gobjects(1, P.n);
for i = 1:P.n
    [X, Y, Z] = cylinder_mesh(pts(:, i), pts(:, i+1), P.Rcyl, 20);
    shade = 0.55 + 0.45 * (i / P.n);
    h.link(i) = surf(ax, X, Y, Z, 'FaceColor', min(S.LM * shade + 0.12, 1), ...
                     'EdgeColor', 'none', 'FaceAlpha', 0.95, ...
                     'FaceLighting', 'gouraud', 'SpecularStrength', 0.35);
end

h.joints = plot3(ax, FK.r_j(1,:), FK.r_j(2,:), FK.r_j(3,:), 'o', ...
                 'MarkerSize', 9, 'MarkerFaceColor', S.hold, ...
                 'MarkerEdgeColor', 'none');
h.spine = plot3(ax, pts(1,:), pts(2,:), pts(3,:), '-', ...
                'Color', [S.text 0.35], 'LineWidth', 1.0);
h.ee = plot3(ax, FK.p_EE(1), FK.p_EE(2), FK.p_EE(3), 'p', ...
             'MarkerSize', 16, 'MarkerFaceColor', S.transfer, 'MarkerEdgeColor','none');

% End-effector triad: x red-ish, y green-ish, z the approach axis.
axLen = 0.45;
triCol = [S.MS; S.transfer; S.dock];
h.triad = gobjects(1,3);
for k = 1:3
    d = FK.R_EE(:,k) * axLen;
    h.triad(k) = plot3(ax, FK.p_EE(1)+[0 d(1)], FK.p_EE(2)+[0 d(2)], ...
                       FK.p_EE(3)+[0 d(3)], '-', 'Color', triCol(k,:), 'LineWidth', 2.2);
end

if showBus
    h.bus = draw_bus(ax, P.busCenter, P.busEdge);
else
    h.bus = [];
end
h.P = P;
end

% ------------------------------------------------------------------ helpers --
function pts = link_points(FK, P)
%LINK_POINTS  Cylinder end points: joint i -> joint i+1, last one -> tip.
pts = zeros(3, P.n+1);
pts(:, 1:P.n) = FK.r_j;
pts(:, P.n+1) = FK.p_EE;
end

function hb = draw_bus(ax, c, a)
S = style();
c = c(:); s = a/2;
V = [ -1 -1 -1;  1 -1 -1;  1  1 -1; -1  1 -1;
      -1 -1  1;  1 -1  1;  1  1  1; -1  1  1 ] * s + c.';
F = [1 2 3 4; 5 6 7 8; 1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8];
hb = patch(ax, 'Vertices', V, 'Faces', F, 'FaceColor', S.MS*0.75, ...
           'EdgeColor', S.MS, 'FaceAlpha', 0.35, 'LineWidth', 1.2);
end
