function h = annotate_hud(fig, partNo, partTitle)
%ANNOTATE_HUD  Lower-third heads-up display, identical on every clip.
%   h = ANNOTATE_HUD(fig, partNo, partTitle) creates the overlay and returns
%   handles. Feed them to HUD_SET each frame; never rebuild the overlay.
%
%   Layout, in figure-normalised units on a 1920x1080 frame:
%       top left      LUNAR RETURN / PART n / 6, then the part title
%       lower third   a 110 px band with four telemetry slots
%       centre        an event flash slot, hidden most of the time
%   Everything sits inside a 24 px safe margin.
%
%   Telemetry values are set in a monospace face. Proportional digits change
%   width as they change value, so a clock rendered in Helvetica visibly
%   shivers at 30 fps; a fixed pitch removes that completely.
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

M    = 24/1920;          % 24 px safe margin, expressed in x-normalised units
band = 110/1080;         % lower-third band height

h.band = patch(h.ax, [0 1 1 0], [0 0 band band], S.bg, ...
               'EdgeColor', 'none', 'FaceAlpha', 0.82);
h.rule = plot(h.ax, [M 1-M], [band band], '-', ...
              'Color', S.accent, 'LineWidth', 2.5);

h.brand = text(h.ax, M, 0.962, sprintf('LUNAR RETURN   /   PART %d / 6', partNo), ...
               'Color', S.accent, 'FontName', S.mono, 'FontSize', 14, ...
               'FontWeight', 'bold', 'VerticalAlignment', 'middle');
h.title = text(h.ax, M, 0.912, partTitle, 'Color', S.text, ...
               'FontName', S.font, 'FontSize', 24, 'VerticalAlignment', 'middle');

xs = M + [0, 0.258, 0.514, 0.770];
labels = {'MISSION TIME', 'RANGE', 'DELTA-V USED', 'TIME RATE'};
h.slotLabel = gobjects(1,4);
h.slotValue = gobjects(1,4);
for k = 1:4
    h.slotLabel(k) = text(h.ax, xs(k), 0.0805, labels{k}, 'Color', S.dim, ...
                          'FontName', S.font, 'FontSize', 13, ...
                          'VerticalAlignment', 'middle');
    h.slotValue(k) = text(h.ax, xs(k), 0.0355, '--', 'Color', S.text, ...
                          'FontName', S.mono, 'FontSize', 25, ...
                          'FontWeight', 'bold', 'VerticalAlignment', 'middle');
end

h.flash = text(h.ax, 0.5, 0.615, '', 'Color', S.dock, 'FontName', S.font, ...
               'FontSize', 42, 'FontWeight', 'bold', ...
               'HorizontalAlignment', 'center', 'Visible', 'off');
h.foot = text(h.ax, 1-M, 0.962, 'MATLAB   /   from first principles', 'Color', S.dim, ...
              'FontName', S.font, 'FontSize', 13, ...
              'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');

uistack(h.ax, 'top');
end
