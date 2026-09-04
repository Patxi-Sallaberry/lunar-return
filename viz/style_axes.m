function style_axes(ax, ttl, xl, yl, zl)
%STYLE_AXES  Apply the dark theme to an axes and optionally label it.
%   STYLE_AXES(ax) themes the axes.
%   STYLE_AXES(ax, title, xlabel, ylabel[, zlabel]) also sets the labels.

S = style();
set(ax, 'Color', S.bg, ...
        'XColor', S.dim, 'YColor', S.dim, 'ZColor', S.dim, ...
        'GridColor', S.gridCol, 'GridAlpha', S.gridAlpha, ...
        'MinorGridColor', S.gridCol, 'MinorGridAlpha', 0.04, ...
        'FontName', S.font, 'FontSize', S.fsSmall, ...
        'Box', 'off', 'LineWidth', 1.0, 'Layer', 'top');
grid(ax, 'on');
hold(ax, 'on');

if nargin >= 2 && ~isempty(ttl)
    title(ax, ttl, 'Color', S.text, 'FontName', S.font, ...
          'FontSize', S.fsAxis, 'FontWeight', 'normal');
end
if nargin >= 3 && ~isempty(xl), xlabel(ax, xl, 'Color', S.dim, 'FontName', S.font); end
if nargin >= 4 && ~isempty(yl), ylabel(ax, yl, 'Color', S.dim, 'FontName', S.font); end
if nargin >= 5 && ~isempty(zl), zlabel(ax, zl, 'Color', S.dim, 'FontName', S.font); end
end
