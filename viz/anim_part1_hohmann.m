function R = anim_part1_hohmann(C)
%ANIM_PART1_HOHMANN  Clip 02: phasing coast, ignition, Hohmann climb, meet-up.
%
%   Loads results/traj_part1.mat and animates it. No physics is recomputed
%   here: if the encoder dies the science is untouched, and if the science
%   changes the clip follows automatically on the next build.
%
%   Camera: a slow pull-back during the phasing coast, so the wait reads as
%   time passing rather than as a stalled frame, and a push-in over the last
%   seconds of the transfer to sell the intercept.

D = load(fullfile(C.resDir, 'traj_part1.mat'));
S = style();
ev = D.events;

% ---------------------------------------------------------- screen timing --
segs = struct('t0', {0, ev.t_burn1, ev.t_arr}, ...
              't1', {ev.t_burn1, ev.t_arr, ev.t_end}, ...
              'screen_s', {5, 9.5, 3.5});
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

% Camera envelope, one value per frame: wide during the wait, tight at arrival.
zoom = zeros(1, nF);
for k = 1:nF
    switch segId(k)
        case 1
            f = frac_in(segId, k, 1);
            zoom(k) = 2150 + 320 * smoothstep(f);          % slow pull-back
        case 2
            f = frac_in(segId, k, 2);
            zoom(k) = 2470 - 120 * smoothstep(max(0, (f-0.75)/0.25));
        otherwise
            zoom(k) = 2350;
    end
end

% ----------------------------------------------------------------- scene ---
fig = new_figure(C.videoRes(1), C.videoRes(2));
ax = axes('Parent', fig, 'Position', [0.070 0.180 0.400 0.680]);
style_axes(ax, '', 'x [km]', 'y [km]');
axis(ax, 'equal');
draw_moon(ax, C.RMoon);
th = linspace(0, 2*pi, 721);
plot(ax, C.R1*cos(th), C.R1*sin(th), '-', 'Color', [S.LM 0.30], 'LineWidth', 1.2);
plot(ax, C.R2*cos(th), C.R2*sin(th), '-', 'Color', [S.MS 0.30], 'LineWidth', 1.2);

% Ghost alphas are deliberately high on the transfer: the green ellipse is the
% single image the clip has to leave behind, so the completed arc must stay
% legible while the bright head still shows where the vehicle is now.
trPre = fading_trail(ax, S.LM,       struct('tail', 260, 'lw', 3.0, 'ghost', 0.30));
trXfr = fading_trail(ax, S.transfer, struct('tail', 500, 'lw', 3.8, 'ghost', 0.55));
trMS  = fading_trail(ax, S.MS,       struct('tail', 260, 'lw', 2.4, 'ghost', 0.22));

hBurn = plot(ax, NaN, NaN, 'o', 'MarkerSize', 26, 'MarkerFaceColor', 'none', ...
             'MarkerEdgeColor', S.dock, 'LineWidth', 2.5, 'Visible', 'off');
scLM = draw_sc(ax, D.rLM(:,1), 'LM', 95, D.vLM(1:2,1));
scMS = draw_sc(ax, D.rMS(:,1), 'MS', 80, D.vMS(1:2,1));

ax2 = axes('Parent', fig, 'Position', [0.575 0.540 0.385 0.320]);
style_axes(ax2, 'LM-MS range', 't [h]', 'km');
set(ax2, 'YScale', 'log');
hR = plot(ax2, NaN, NaN, '-', 'Color', S.hold, 'LineWidth', 2.6);
xlim(ax2, [0 ev.t_end/3600]); ylim(ax2, [1 max(range_km)*1.6]);

ax3 = axes('Parent', fig, 'Position', [0.575 0.195 0.385 0.245]);
style_axes(ax3, 'LM inertial speed', 't [h]', 'km/s');
hV = plot(ax3, NaN, NaN, '-', 'Color', S.transfer, 'LineWidth', 2.6);
xlim(ax3, [0 ev.t_end/3600]); ylim(ax3, [min(speed)-0.02 max(speed)+0.02]);

hud = annotate_hud(fig, 1, 'Phasing and Hohmann transfer   /   100 km to 400 km LLO');

R = render_clip(fig, @frame, nF, '02_hohmann', C);

% ------------------------------------------------------------------ frame --
    function frame(k)
        i = idx(k);
        iPre = min(i, ev.iBurn1);
        update_trail(trPre, D.rLM(1,:), D.rLM(2,:), [], iPre);
        if i > ev.iBurn1
            update_trail(trXfr, D.rLM(1,:), D.rLM(2,:), [], i, ev.iBurn1);
        end
        update_trail(trMS, D.rMS(1,:), D.rMS(2,:), [], i);

        move_sc(scLM, D.rLM(:,i), D.vLM(1:2,i));
        move_sc(scMS, D.rMS(:,i), D.vMS(1:2,i));
        set(ax, 'XLim', zoom(k)*[-1 1], 'YLim', zoom(k)*[-1 1]);

        set(hR, 'XData', D.t(1:i)/3600, 'YData', max(range_km(1:i), 1));
        set(hV, 'XData', D.t(1:i)/3600, 'YData', speed(1:i));

        flash = '';
        s = segId(k);
        kIn = k - find(segId == s, 1) + 1;
        if s == 2 && kIn <= 6
            flash = sprintf('\\DeltaV_1   %.1f m/s', D.H.dV1_ms);
            set(hBurn, 'XData', D.rLM(1,ev.iBurn1), 'YData', D.rLM(2,ev.iBurn1), ...
                'Visible', 'on', 'MarkerSize', 18 + 5*kIn);
        elseif s == 3 && kIn <= 6
            flash = sprintf('RENDEZVOUS   \\DeltaV_2   %.1f m/s', D.H.dV2_ms);
            set(hBurn, 'XData', D.rLM(1,ev.iArr), 'YData', D.rLM(2,ev.iArr), ...
                'Visible', 'on', 'MarkerSize', 18 + 5*kIn);
        else
            set(hBurn, 'Visible', 'off');
        end

        hud_set(hud, {hms(tSel(k)), sprintf('%7.1f km', range_km(i)), ...
                      sprintf('%5.1f m/s', dVused(i)), ...
                      sprintf('x%4.0f', rate(s))}, [], flash);
    end
end

% ------------------------------------------------------------------ helpers --
function f = frac_in(segId, k, s)
ii = find(segId == s);
f = (k - ii(1)) / max(1, numel(ii) - 1);
end

function y = smoothstep(x)
x = max(0, min(1, x));
y = 3*x.^2 - 2*x.^3;
end
