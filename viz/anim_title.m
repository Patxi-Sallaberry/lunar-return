function R = anim_title(C)
%ANIM_TITLE  Clip 01: the opening card.
%   Four seconds, three ideas, no narration. The Moon and the two orbits are
%   the same primitives the technical clips use, so the reel reads as one
%   piece rather than a slideshow with a cover.

S = style();
screen_s = 4;
nF = round(screen_s * C.videoFps);

fig = new_figure(C.videoRes(1), C.videoRes(2));
ax = axes('Parent', fig, 'Position', [0 0 1 1]);
hold(ax, 'on');
set(ax, 'Color', S.bg, 'XLim', [0 16], 'YLim', [0 9], 'XTick', [], 'YTick', [], ...
        'Visible', 'off', 'XLimMode','manual', 'YLimMode','manual');
set(ax, 'DataAspectRatio', [1 1 1]);

% Moon and the two orbits, right-hand third.
% Moon vignette lives in the upper right, clear of every text block.
cx = 13.6; cy = 6.0; Rm = 1.45;
draw_moon(ax, Rm, [cx; cy]);
th = linspace(0, 2*pi, 400);
plot(ax, cx + Rm*1.06*cos(th), cy + Rm*1.06*sin(th), '-', 'Color', [S.LM 0.5], 'LineWidth', 1.6);
plot(ax, cx + Rm*1.24*cos(th), cy + Rm*1.24*sin(th), '-', 'Color', [S.MS 0.5], 'LineWidth', 1.6);
hArc = plot(ax, NaN, NaN, '-', 'Color', S.transfer, 'LineWidth', 3.4);
hDot = plot(ax, NaN, NaN, 'o', 'MarkerSize', 13, 'MarkerFaceColor', S.LM, 'MarkerEdgeColor','none');
hMS  = plot(ax, NaN, NaN, 's', 'MarkerSize', 14, 'MarkerFaceColor', S.MS, 'MarkerEdgeColor','none');

hRule = plot(ax, [0.85 0.85], [1.2 1.2], '-', 'Color', S.accent, 'LineWidth', 4);

hKicker = text(ax, 0.85, 7.35, 'MATLAB  ·  FROM SCRATCH  ·  NO TOOLBOXES', ...
               'Color', S.accent, 'FontName', S.font, 'FontSize', 20, 'FontWeight','bold');
hTitle = text(ax, 0.85, 6.25, 'LUNAR RETURN', 'Color', S.text, ...
              'FontName', S.font, 'FontSize', 66, 'FontWeight', 'bold');
hSub = text(ax, 0.85, 5.35, ['Rendezvous, proximity operations and robotic berthing' newline ...
                             'for an Artemis-style crewed ascent from the Moon'], ...
            'Color', S.dim, 'FontName', S.font, 'FontSize', 23, ...
            'VerticalAlignment', 'top');

bullets = { 'Hohmann transfer, phasing, Keplerian verification', ...
            'Hill-Clohessy-Wiltshire hold and V-bar docking', ...
            'J2 and third-body drift, CR3BP, 5R berthing arm' };
hB = gobjects(1,3);
hDotM = gobjects(1,3);
for k = 1:3
    y = 3.35 - 0.72*(k-1);
    hDotM(k) = plot(ax, 1.02, y, 'o', 'MarkerSize', 9, 'MarkerFaceColor', S.transfer, ...
                    'MarkerEdgeColor','none', 'Visible','off');
    hB(k) = text(ax, 1.45, y, bullets{k}, 'Color', S.text, 'FontName', S.font, ...
                 'FontSize', 26, 'Visible', 'off');
end

R = render_clip(fig, @frame, nF, '01_title', C);

    function frame(k)
        f = k / nF;

        % Orbit vignette: the chaser climbs onto the outer orbit.
        a = 2*pi * 1.35 * f - pi/2;
        tArc = linspace(-pi/2, a, 200);
        rr = Rm * (1.06 + 0.18 * max(0, min(1, (tArc + pi/2)/(2*pi*0.9))));
        set(hArc, 'XData', cx + rr.*cos(tArc), 'YData', cy + rr.*sin(tArc));
        set(hDot, 'XData', cx + rr(end)*cos(a), 'YData', cy + rr(end)*sin(a));
        aMS = -pi/2 + 2*pi*0.75*f + 0.7;
        set(hMS, 'XData', cx + Rm*1.24*cos(aMS), 'YData', cy + Rm*1.24*sin(aMS));

        set(hRule, 'XData', [0.85, 0.85 + 6.2*min(1, f*3)]);

        for q = 1:3
            on = f > 0.28 + 0.13*(q-1);
            set(hB(q),    'Visible', tf2on(on));
            set(hDotM(q), 'Visible', tf2on(on));
        end
        set(hKicker, 'Visible', tf2on(f > 0.06));
        set(hSub,    'Visible', tf2on(f > 0.16));
    end
end

function s = tf2on(tf)
if tf, s = 'on'; else, s = 'off'; end
end
