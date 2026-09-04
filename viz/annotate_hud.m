function h = annotate_hud(fig, partNo, partTitle)
%ANNOTATE_HUD  Lower-third heads-up display, identical on every clip.
%   h = ANNOTATE_HUD(fig, partNo, partTitle) creates the overlay and returns
%   handles. Feed them to HUD_SET each frame; never rebuild the overlay.
%
%   Layout:
%       top left     LUNAR RETURN  ·  PART n / 6, then the part title
%       lower third  four telemetry slots (time, range, delta-v, time rate)
%       centre       an event flash slot, hidden most of the time
%
%   HOLD IS ENABLED BEFORE ANYTHING IS DRAWN. A plot() call on an axes with
%   hold off resets the axes, which silently restores Visible, the limits and
%   the background colour, and the overlay then paints over the whole clip.

S = style();
h.ax = axes('Parent', fig, 'Position', [0 0 1 1]);
hold(h.ax, 'on');
set(h.ax, 'Color', 'none', 'XLim', [0 1], 'YLim', [0 1], ...
          'XTick', [], 'YTick', [], 'Visible', 'off', ...
          'XLimMode', 'manual', 'YLimMode', 'manual', ...
          'HitTest', 'off', 'PickableParts', 'none');

% Lower-third band, drawn as a translucent strip.
h.band = patch(h.ax, [0 1 1 0], [0 0 0.135 0.135], S.bg, ...
               'EdgeColor', 'none', 'FaceAlpha', 0.78);
h.rule = plot(h.ax, [0.03 0.97], [0.137 0.137], '-', ...
              'Color', S.accent, 'LineWidth', 2.5);

h.brand = text(h.ax, 0.030, 0.966, sprintf('LUNAR RETURN   ·   PART %d / 6', partNo), ...
               'Color', S.accent, 'FontName', S.font, 'FontSize', 15, ...
               'FontWeight', 'bold', 'VerticalAlignment', 'middle');
h.title = text(h.ax, 0.030, 0.916, partTitle, 'Color', S.text, ...
               'FontName', S.font, 'FontSize', 23, 'VerticalAlignment', 'middle');

xs = [0.030 0.290 0.545 0.800];
labels = {'MISSION TIME', 'RANGE', '\DeltaV USED', 'TIME RATE'};
h.slotLabel = gobjects(1,4);
h.slotValue = gobjects(1,4);
for k = 1:4
    h.slotLabel(k) = text(h.ax, xs(k), 0.101, labels{k}, 'Color', S.dim, ...
                          'FontName', S.font, 'FontSize', 13, ...
                          'VerticalAlignment', 'middle');
    h.slotValue(k) = text(h.ax, xs(k), 0.052, '--', 'Color', S.text, ...
                          'FontName', S.font, 'FontSize', 26, ...
                          'VerticalAlignment', 'middle');
end

h.flash = text(h.ax, 0.5, 0.63, '', 'Color', S.dock, 'FontName', S.font, ...
               'FontSize', 42, 'FontWeight', 'bold', ...
               'HorizontalAlignment', 'center', 'Visible', 'off');
h.foot = text(h.ax, 0.970, 0.966, 'MATLAB  ·  from scratch', 'Color', S.dim, ...
              'FontName', S.font, 'FontSize', 13, ...
              'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');

uistack(h.ax, 'top');
end
