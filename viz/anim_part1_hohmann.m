function R = anim_part1_hohmann(C)
%ANIM_PART1_HOHMANN  Clip 02: phasing coast, ignition, Hohmann climb, meet-up.
%
%   Loads results/traj_part1.mat and animates it. No physics is recomputed
%   here: if the encoder dies, the science is untouched, and if the science
%   changes the clip follows automatically on the next build.

D = load(fullfile(C.resDir, 'traj_part1.mat'));
S = style();
ev = D.events;

% ---------------------------------------------------------- screen timing --
segs = struct('t0', {0, ev.t_burn1, ev.t_arr}, ...
              't1', {ev.t_burn1, ev.t_arr, ev.t_end}, ...
              'screen_s', {6, 10, 4});
[idx, tSel, segId] = timewarp(D.t, segs, C.videoFps);
nF = numel(idx);

rate = zeros(1, numel(segs));
for s = 1:numel(segs)
    rate(s) = (segs(s).t1 - segs(s).t0) / segs(s).screen_s;
end

range_km = sqrt(sum((D.rLM - D.rMS).^2, 1));
speed    = sqrt(sum(D.vLM.^2, 1));
dVused   = zeros(1, numel(D.t));
dVused(ev.iBurn1:end) = D.H.dV1_ms;
dVused(ev.iArr:end)   = D.H.dVtot_ms;

% ----------------------------------------------------------------- scene ---
fig = new_figure(C.videoRes(1), C.videoRes(2));
ax = axes('Parent', fig, 'Position', [0.070 0.180 0.400 0.695]);
style_axes(ax, '', 'x [km]', 'y [km]');
axis(ax, 'equal');
draw_moon(ax, C.RMoon);
th = linspace(0, 2*pi, 721);
plot(ax, C.R1*cos(th), C.R1*sin(th), '-', 'Color', [S.LM 0.35], 'LineWidth', 1.2);
plot(ax, C.R2*cos(th), C.R2*sin(th), '-', 'Color', [S.MS 0.35], 'LineWidth', 1.2);
hPre = plot(ax, NaN, NaN, '-', 'Color', S.LM,       'LineWidth', 2.4);
hTr  = plot(ax, NaN, NaN, '-', 'Color', S.transfer, 'LineWidth', 3.0);
hMSt = plot(ax, NaN, NaN, '-', 'Color', [S.MS 0.75],'LineWidth', 1.8);
hBurn = plot(ax, NaN, NaN, 'o', 'MarkerSize', 26, 'MarkerFaceColor', 'none', ...
             'MarkerEdgeColor', S.dock, 'LineWidth', 2.5, 'Visible', 'off');
scLM = draw_sc(ax, D.rLM(:,1), 'LM', 95, D.vLM(1:2,1));
scMS = draw_sc(ax, D.rMS(:,1), 'MS', 80, D.vMS(1:2,1));
xlim(ax, 2380*[-1 1]); ylim(ax, 2380*[-1 1]);

ax2 = axes('Parent', fig, 'Position', [0.575 0.545 0.385 0.330]);
style_axes(ax2, 'LM-MS range', 't [h]', 'km');
set(ax2, 'YScale', 'log');
hR = plot(ax2, NaN, NaN, '-', 'Color', S.hold, 'LineWidth', 2.4);
xlim(ax2, [0 ev.t_end/3600]); ylim(ax2, [1 max(range_km)*1.6]);

ax3 = axes('Parent', fig, 'Position', [0.575 0.195 0.385 0.255]);
style_axes(ax3, 'LM inertial speed', 't [h]', 'km/s');
hV = plot(ax3, NaN, NaN, '-', 'Color', S.transfer, 'LineWidth', 2.4);
xlim(ax3, [0 ev.t_end/3600]); ylim(ax3, [min(speed)-0.02 max(speed)+0.02]);

hud = annotate_hud(fig, 1, 'Phasing and Hohmann transfer  ·  100 km \rightarrow 400 km LLO');

R = render_clip(fig, @frame, nF, '02_hohmann', C);

% ------------------------------------------------------------------ frame --
    function frame(k)
        i = idx(k);
        iPre = 1:min(i, ev.iBurn1);
        set(hPre, 'XData', D.rLM(1,iPre), 'YData', D.rLM(2,iPre));
        if i > ev.iBurn1
            iTr = ev.iBurn1:i;
            set(hTr, 'XData', D.rLM(1,iTr), 'YData', D.rLM(2,iTr));
        end
        set(hMSt, 'XData', D.rMS(1,1:i), 'YData', D.rMS(2,1:i));
        move_sc(scLM, D.rLM(:,i), D.vLM(1:2,i));
        move_sc(scMS, D.rMS(:,i), D.vMS(1:2,i));
        set(hR, 'XData', D.t(1:i)/3600, 'YData', max(range_km(1:i), 1));
        set(hV, 'XData', D.t(1:i)/3600, 'YData', speed(1:i));

        flash = '';
        s = segId(k);
        kInSeg = k - find(segId == s, 1) + 1;
        if s == 2 && kInSeg <= 12
            flash = sprintf('\\DeltaV_1   %.1f m/s', D.H.dV1_ms);
            set(hBurn, 'XData', D.rLM(1,ev.iBurn1), 'YData', D.rLM(2,ev.iBurn1), ...
                'Visible', 'on', 'MarkerSize', 20 + 3*kInSeg);
        elseif s == 3 && kInSeg <= 14
            flash = sprintf('RENDEZVOUS   \\DeltaV_2   %.1f m/s', D.H.dV2_ms);
            set(hBurn, 'XData', D.rLM(1,ev.iArr), 'YData', D.rLM(2,ev.iArr), ...
                'Visible', 'on', 'MarkerSize', 20 + 3*kInSeg);
        else
            set(hBurn, 'Visible', 'off');
        end

        hud_set(hud, {hms(tSel(k)), sprintf('%.1f km', range_km(i)), ...
                      sprintf('%.1f m/s', dVused(i)), ...
                      sprintf('x %.0f', rate(s))}, [], flash);
    end
end
