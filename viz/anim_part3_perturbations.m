function R = anim_part3_perturbations(C)
%ANIM_PART3_PERTURBATIONS  Clip 04: what J2 does to a Keplerian rendezvous.
%
%   Solid cyan is the design trajectory, dashed violet the same manoeuvre plan
%   flown against lunar J2 and the Earth third body. They look identical for
%   ten hours and then miss each other by kilometres, which is the entire
%   point of the clip. Loads results/traj_part3.mat only.

D = load(fullfile(C.resDir, 'traj_part3.mat'));
S = style();

t_end = D.t(end);
segs = struct('t0', {0, D.t_burn, t_end}, ...
              't1', {D.t_burn, t_end, t_end}, ...
              'screen_s', {4, 6, 3});
[idx, tSel, segId] = timewarp(D.t, segs, C.videoFps);
nF = numel(idx);

drift_km = sqrt(sum((D.rLM_3b - D.rLM_kep).^2, 1));
range_km = sqrt(sum((D.rLM_3b - D.rMS_3b).^2, 1));
missVec  = D.d_J2_3B;
missNorm = norm(missVec);

% ----------------------------------------------------------------- scene ---
fig = new_figure(C.videoRes(1), C.videoRes(2));
ax = axes('Parent', fig, 'Position', [0.070 0.180 0.400 0.695]);
style_axes(ax, '', 'x [km]', 'y [km]');
axis(ax, 'equal');
draw_moon(ax, C.RMoon);
hKep = plot(ax, NaN, NaN, '-',  'Color', S.LM, 'LineWidth', 2.6);
hPer = plot(ax, NaN, NaN, '--', 'Color', S.J2, 'LineWidth', 2.6);
hMS  = plot(ax, NaN, NaN, '-',  'Color', [S.MS 0.8], 'LineWidth', 1.8);
hLMk = plot(ax, NaN, NaN, 'o', 'MarkerSize', 11, 'MarkerFaceColor', S.LM,  'MarkerEdgeColor','none');
hLMp = plot(ax, NaN, NaN, 'o', 'MarkerSize', 11, 'MarkerFaceColor', S.J2,  'MarkerEdgeColor','none');
hMSm = plot(ax, NaN, NaN, 's', 'MarkerSize', 12, 'MarkerFaceColor', S.MS,  'MarkerEdgeColor','none');
xlim(ax, 2380*[-1 1]); ylim(ax, 2380*[-1 1]);
legend(ax, [hKep hPer hMS], {'Keplerian design','J2 + Earth third body','mothership'}, ...
       'TextColor', S.text, 'Color', S.panel, 'EdgeColor', S.dim, ...
       'Location','south', 'FontSize', S.fsSmall);

ax2 = axes('Parent', fig, 'Position', [0.575 0.545 0.385 0.330]);
style_axes(ax2, 'displacement from the Keplerian design', 't [h]', 'km');
set(ax2, 'YScale', 'log');
hD = plot(ax2, NaN, NaN, '-', 'Color', S.J2, 'LineWidth', 2.6);
xlim(ax2, [0 t_end/3600]); ylim(ax2, [1e-3 max(drift_km)*2]);

ax3 = axes('Parent', fig, 'Position', [0.590 0.200 0.360 0.245]);
style_axes(ax3, 'arrival zoom', '\Deltax [km]', '\Deltay [km]');
axis(ax3, 'equal');
hZk = plot(ax3, NaN, NaN, '-',  'Color', S.LM, 'LineWidth', 2.0);
hZp = plot(ax3, NaN, NaN, '--', 'Color', S.J2, 'LineWidth', 2.0);
hZm = plot(ax3, 0, 0, 's', 'MarkerSize', 13, 'MarkerFaceColor', S.MS, 'MarkerEdgeColor','none');
hArrow = quiver(ax3, 0, 0, 0, 0, 0, 'Color', S.warn, 'LineWidth', 3.0, 'MaxHeadSize', 0.8);
hMissTxt = text(ax3, 0, 0, '', 'Color', S.warn, 'FontName', S.font, ...
                'FontSize', 20, 'FontWeight', 'bold');
set([ax3.Children; ax3], 'Visible', 'off');

hud = annotate_hud(fig, 3, 'Perturbed dynamics  ·  Cowell with lunar J2 and Earth third body');

R = render_clip(fig, @frame, nF, '04_perturbations', C);

% ------------------------------------------------------------------ frame --
    function frame(k)
        i = idx(k);
        set(hKep, 'XData', D.rLM_kep(1,1:i), 'YData', D.rLM_kep(2,1:i));
        set(hPer, 'XData', D.rLM_3b(1,1:i),  'YData', D.rLM_3b(2,1:i));
        set(hMS,  'XData', D.rMS_3b(1,1:i),  'YData', D.rMS_3b(2,1:i));
        set(hLMk, 'XData', D.rLM_kep(1,i),   'YData', D.rLM_kep(2,i));
        set(hLMp, 'XData', D.rLM_3b(1,i),    'YData', D.rLM_3b(2,i));
        set(hMSm, 'XData', D.rMS_3b(1,i),    'YData', D.rMS_3b(2,i));
        set(hD,   'XData', D.t(1:i)/3600, 'YData', max(drift_km(1:i), 1e-3));

        flash = '';
        if segId(k) == 3
            % Final beat: reveal the miss geometry.
            set([ax3; ax3.Children], 'Visible', 'on');
            c0 = D.rMS_3b(:,end);
            set(hZk, 'XData', D.rLM_kep(1,end-399:end)-c0(1), 'YData', D.rLM_kep(2,end-399:end)-c0(2));
            set(hZp, 'XData', D.rLM_3b(1,end-399:end)-c0(1),  'YData', D.rLM_3b(2,end-399:end)-c0(2));
            f = min(1, (k - find(segId == 3, 1) + 1) / 20);
            set(hArrow, 'UData', missVec(1)*f, 'VData', missVec(2)*f);
            set(hMissTxt, 'Position', [missVec(1)*1.05, missVec(2)*1.05, 0], ...
                'String', sprintf('%.1f km', missNorm));
            L = max(abs([missVec(1) missVec(2)])) * 2.6;
            set(ax3, 'XLim', [-L L], 'YLim', [-L L]);
            if k > nF - 30
                flash = sprintf('J2 MISS   %.1f km', missNorm);
            end
        end

        rate = (segs(segId(k)).t1 - segs(segId(k)).t0) / segs(segId(k)).screen_s;
        if rate > 0, rateStr = sprintf('x %.0f', rate); else, rateStr = 'HOLD'; end
        hud_set(hud, {hms(tSel(k)), sprintf('%.1f km', range_km(i)), ...
                      sprintf('%.3f km', drift_km(i)), rateStr}, ...
                {'MISSION TIME', 'LM-MS RANGE', 'DRIFT vs KEPLER', 'TIME RATE'}, flash);
    end
end
