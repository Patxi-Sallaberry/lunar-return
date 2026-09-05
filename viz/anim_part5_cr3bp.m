function R = anim_part5_cr3bp(C)
%ANIM_PART5_CR3BP  Clip 05: the transfer re-converged in the Earth-Moon CR3BP.
%
%   Top-down synodic view, Moon-centered. The arc is the same climb as clip 02
%   but the frame now rotates with the Earth-Moon line and the Earth is a real
%   primary. Loads results/traj_part5.mat only.

D = load(fullfile(C.resDir, 'traj_part5.mat'));
S = style();

screen_s = 11;
nF = round(screen_s * C.videoFps);
iL = round(linspace(1, size(D.x_syn_LM, 2), nF));
iM = round(linspace(1, size(D.x_syn_MS, 2), nF));
tL = linspace(0, D.tof_s, nF);

rangeKm = sqrt(sum((interp1(1:size(D.x_syn_LM,2), D.x_syn_LM.', iL).' - ...
                    interp1(1:size(D.x_syn_MS,2), D.x_syn_MS.', iM).').^2, 1));

% ----------------------------------------------------------------- scene ---
fig = new_figure(C.videoRes(1), C.videoRes(2));
ax = axes('Parent', fig, 'Position', [0.070 0.180 0.400 0.695]);
style_axes(ax, '', 'x_{syn} [km]', 'y_{syn} [km]');
axis(ax, 'equal');
draw_moon(ax, D.RMoon);
plot(ax, D.ms_ring(1,:), D.ms_ring(2,:), '-', 'Color', [S.MS 0.45], 'LineWidth', 1.4);
trTr = fading_trail(ax, S.transfer, struct('tail', 120, 'lw', 3.8, 'ghost', 0.60));
trMs = fading_trail(ax, S.MS,       struct('tail', 120, 'lw', 2.6, 'ghost', 0.32));
hL  = plot(ax, NaN, NaN, 'o', 'MarkerSize', 12, 'MarkerFaceColor', S.LM, 'MarkerEdgeColor','none');
hM  = plot(ax, NaN, NaN, 's', 'MarkerSize', 13, 'MarkerFaceColor', S.MS, 'MarkerEdgeColor','none');
quiver(ax, 0, 0, -1500, 0, 0, 'Color', S.third, 'LineWidth', 2.4, 'MaxHeadSize', 0.4);
text(ax, -1900, 190, 'to Earth', 'Color', S.third, 'FontName', S.font, 'FontSize', 15);
xlim(ax, 2380*[-1 1]); ylim(ax, 2380*[-1 1]);

ax2 = axes('Parent', fig, 'Position', [0.575 0.545 0.385 0.330]);
style_axes(ax2, 'LM-MS range in the rotating frame', 't [min]', 'km');
set(ax2, 'YScale', 'log');
hR = plot(ax2, NaN, NaN, '-', 'Color', S.hold, 'LineWidth', 2.4);
xlim(ax2, [0 D.tof_s/60]); ylim(ax2, [max(min(rangeKm),1e-2) max(rangeKm)*1.6]);

ax3 = axes('Parent', fig, 'Position', [0.575 0.195 0.385 0.255]);
style_axes(ax3, '', '', '');
set(ax3, 'XLim', [0 1], 'YLim', [0 1], 'XTick', [], 'YTick', [], 'Visible', 'off');
lines = { sprintf('\\mu = %.5f,  LU = 384 400 km', C.muCR3BP), ...
          sprintf('shooting on [\\delta v_x, \\delta v_y, TOF]'), ...
          sprintf('converged miss  %.1f m', D.miss_km*1e3), ...
          sprintf('TOF  %.1f s', D.tof_s), ...
          sprintf('\\DeltaV_1  %.5f km/s      \\DeltaV_2  %.5f km/s', D.dV1, D.dV2) };
hTxt = gobjects(1, numel(lines));
for q = 1:numel(lines)
    hTxt(q) = text(ax3, 0.02, 0.90 - 0.20*(q-1), lines{q}, 'Color', S.text, ...
                   'FontName', S.font, 'FontSize', 17, 'Visible', 'off');
end

hud = annotate_hud(fig, 5, 'CR3BP verification  ·  synodic single shooting');

R = render_clip(fig, @frame, nF, '05_cr3bp', C);

% ------------------------------------------------------------------ frame --
    function frame(k)
        update_trail(trTr, D.x_syn_LM(1,:), D.x_syn_LM(2,:), [], iL(k));
        update_trail(trMs, D.x_syn_MS(1,:), D.x_syn_MS(2,:), [], iM(k));
        set(hL,  'XData', D.x_syn_LM(1,iL(k)),   'YData', D.x_syn_LM(2,iL(k)));
        set(hM,  'XData', D.x_syn_MS(1,iM(k)),   'YData', D.x_syn_MS(2,iM(k)));
        set(hR,  'XData', tL(1:k)/60, 'YData', max(rangeKm(1:k), 1e-2));

        % Reveal the summary one line at a time over the second half.
        for q = 1:numel(hTxt)
            show = k > nF*0.45 + (q-1) * nF*0.08;
            set(hTxt(q), 'Visible', onoff(show));
        end

        flash = '';
        if k > nF - 16
            flash = sprintf('MISS  %.1f m', D.miss_km*1e3);
        end
        hud_set(hud, {hms(tL(k)), sprintf('%7.1f km', rangeKm(k)), ...
                      sprintf('%5.1f m/s', (D.dV1 + D.dV2*(k==nF))*1e3), ...
                      sprintf('x%4.0f', D.tof_s/screen_s)}, ...
                {'TRANSFER TIME', 'RANGE', '\DeltaV USED', 'TIME RATE'}, flash);
    end
end

function s = onoff(tf)
if tf, s = 'on'; else, s = 'off'; end
end
