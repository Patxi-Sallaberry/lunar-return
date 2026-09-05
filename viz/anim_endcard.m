function R = anim_endcard(C, metrics)
%ANIM_ENDCARD  Clip 07: the closing numbers.
%   Every figure on this card is read out of the metrics struct produced by
%   the run that just finished. Nothing is typed in, so the card can never
%   drift out of sync with the simulation.

S = style();
screen_s = 6;
nF = round(screen_s * C.videoFps);

rows = build_rows(metrics);

fig = new_figure(C.videoRes(1), C.videoRes(2));
ax = axes('Parent', fig, 'Position', [0 0 1 1]);
hold(ax, 'on');
set(ax, 'Color', S.bg, 'XLim', [0 16], 'YLim', [0 9], 'XTick', [], 'YTick', [], ...
        'Visible', 'off', 'XLimMode','manual', 'YLimMode','manual', ...
        'DataAspectRatio', [1 1 1]);

text(ax, 1.0, 8.05, 'LUNAR RETURN  ·  RESULTS', 'Color', S.accent, ...
     'FontName', S.font, 'FontSize', 24, 'FontWeight', 'bold');
plot(ax, [1.0 15.0], [7.72 7.72], '-', 'Color', [S.accent 0.6], 'LineWidth', 2.5);

hL = gobjects(1, numel(rows));
hV = gobjects(1, numel(rows));
for k = 1:numel(rows)
    y = 7.00 - 0.80*(k-1);
    hL(k) = text(ax, 1.0, y, rows{k}{1}, 'Color', S.dim, 'FontName', S.font, ...
                 'FontSize', 26, 'Visible', 'off');
    hV(k) = text(ax, 9.6, y, rows{k}{2}, 'Color', S.text, 'FontName', S.font, ...
                 'FontSize', 32, 'FontWeight', 'bold', 'Visible', 'off');
end

% Two separate lines: a single one collides with the repository URL.
hFoot = text(ax, 1.0, 1.30, 'MATLAB  ·  ode45  ·  HCW STM  ·  Cowell J2 + 3B  ·  CR3BP  ·  WDLS', ...
             'Color', S.dim, 'FontName', S.font, 'FontSize', 20, 'Visible', 'off');
hRepo = text(ax, 1.0, 0.62, 'github.com/<user>/lunar-return-rendezvous', ...
             'Color', S.accent, 'FontName', S.font, 'FontSize', 22, ...
             'FontWeight', 'bold', 'Visible', 'off');

R = render_clip(fig, @frame, nF, '07_endcard', C);

    function frame(k)
        f = k / nF;
        for q = 1:numel(rows)
            on = f > 0.06 + 0.085*(q-1);
            set(hL(q), 'Visible', tf2on(on));
            set(hV(q), 'Visible', tf2on(on));
        end
        set(hFoot, 'Visible', tf2on(f > 0.68));
        set(hRepo, 'Visible', tf2on(f > 0.74));
    end
end

% ------------------------------------------------------------------ helpers --
function rows = build_rows(m)
rows = {};
rows{end+1} = {'Hohmann \DeltaV total',    fmt(m, 'dVtot_ms',      '%.2f m/s')};
rows{end+1} = {'Phasing wait + transfer',  fmt(m, 't_mission_h',   '%.2f h')};
rows{end+1} = {'Hold + docking \DeltaV',   fmt(m, 'dV_prox_ms',    '%.2f m/s')};
rows{end+1} = {'J2 + third-body miss',     fmt(m, 'miss_J2_3B_km', '%.1f km')};
rows{end+1} = {'CR3BP correction',         fmt(m, 'dV_extra_mms',  '%.1f mm/s')};
rows{end+1} = {'Arm reach  ·  5R',         fmt(m, 'reach_m',       '%.1f m')};
rows{end+1} = {'IK position residual',     fmt(m, 'ik_res_mm',     '%.2f mm')};
end

function s = fmt(m, field, spec)
if isfield(m, field) && isnumeric(m.(field)) && isscalar(m.(field)) && isfinite(m.(field))
    s = sprintf(spec, m.(field));
else
    s = 'n/a';
end
end

function s = tf2on(tf)
if tf, s = 'on'; else, s = 'off'; end
end
