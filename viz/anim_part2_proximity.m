function R = anim_part2_proximity(C)
%ANIM_PART2_PROXIMITY  Clip 03: free drift, hold acquisition, V-bar docking.
%
%   Three hard-cut phases, each with its own zoom level, because the story
%   spans four orders of magnitude in range: 21 km of uncorrected drift down
%   to a docking port contact. Loads results/traj_part2.mat only.

D = load(fullfile(C.resDir, 'traj_part2.mat'));
S = style();

phases = struct( ...
    'name',   {'FREE DRIFT', 'ACTIVE CORRECTION', 'V-BAR APPROACH'}, ...
    'title',  {'Uncorrected injection error, 3 mothership orbits', ...
               'Two-impulse HCW transfer to the 50 m hold point', ...
               'Forced straight-line docking, 5 legs plus brake'}, ...
    'screen', {5, 6, 8});

t = {D.t_drift, D.t_hold, D.t_dock};
x = {D.x_hcw,   D.x_hold, D.x_dock};

% Cumulative delta-v spent, per phase, in m/s.
dvA = zeros(1, numel(t{1}));
dv1 = norm(D.dV_hold_1); dv2 = norm(D.dV_hold_2);
dvB = dv1 * ones(1, numel(t{2})); dvB(end) = dv1 + dv2;
dvC = (dv1 + dv2) * ones(1, numel(t{3}));
cum = dv1 + dv2;
for k = 1:size(D.dock_impulses, 2)
    cum = cum + norm(D.dock_impulses(:,k));
    dvC(t{3} >= D.dock_t_impulse(k)) = cum;
end
dv = {dvA, dvB, dvC};

% Frame plan and per-phase view limits.
nF = 0; plan = [];
for p = 1:3
    nf = round(phases(p).screen * C.videoFps);
    ii = round(linspace(1, numel(t{p}), nf));
    plan = [plan, [p*ones(1,nf); ii]];  %#ok<AGROW>
    nF = nF + nf;
end

% Centre each phase on its own corridor instead of on the origin: the docking
% leg is a 50 m straight line and would otherwise sit in the corner of a view
% sized for a 21 km drift.
limX = zeros(3,2); limZ = zeros(3,2);
for p = 1:3
    xr = [min(x{p}(1,:)) max(x{p}(1,:))];
    zr = [min(x{p}(3,:)) max(x{p}(3,:))];
    ctr = [mean(xr) mean(zr)];
    L = 1.18 * max([diff(xr)/2, diff(zr)/2, 30]);
    limX(p,:) = ctr(1) + [-L L];
    limZ(p,:) = ctr(2) + [-L L];
end

% ----------------------------------------------------------------- scene ---
fig = new_figure(C.videoRes(1), C.videoRes(2));
ax = axes('Parent', fig, 'Position', [0.075 0.180 0.400 0.695]);
style_axes(ax, '', 'x   V-bar [m]', 'z   R-bar [m]');
axis(ax, 'equal');
hPath = plot(ax, NaN, NaN, '-', 'Color', S.LM, 'LineWidth', 2.6);
hHold = plot(ax, D.r_hold(1), D.r_hold(3), 'd', 'MarkerSize', 13, ...
             'MarkerFaceColor', S.hold, 'MarkerEdgeColor', 'none');
hPort = plot(ax, 0, 0, 's', 'MarkerSize', 16, 'MarkerFaceColor', S.MS, ...
             'MarkerEdgeColor', 'none');
hChase = plot(ax, NaN, NaN, 'o', 'MarkerSize', 12, 'MarkerFaceColor', S.transfer, ...
              'MarkerEdgeColor', 'none');
hVbar = plot(ax, [0 0], [0 0], '--', 'Color', [S.dim 0.7], 'LineWidth', 1.2);

ax2 = axes('Parent', fig, 'Position', [0.575 0.545 0.385 0.330]);
style_axes(ax2, 'range to the docking port', 'time [s]', 'm');
set(ax2, 'YScale', 'log');
hRng = plot(ax2, NaN, NaN, '-', 'Color', S.hold, 'LineWidth', 2.4);

ax3 = axes('Parent', fig, 'Position', [0.575 0.195 0.385 0.255]);
style_axes(ax3, 'cross-track y (out of plane)', 'time [s]', 'm');
hY = plot(ax3, NaN, NaN, '-', 'Color', S.J2, 'LineWidth', 2.4);

hud = annotate_hud(fig, 2, phases(1).title);

lastPhase = 0;      % shared with the nested frame callback
R = render_clip(fig, @frame, nF, '03_proximity', C);

% ------------------------------------------------------------------ frame --
    function frame(k)
        p = plan(1,k);
        i = plan(2,k);
        tp = t{p}; xp = x{p};

        if lastPhase ~= p
            lastPhase = p;
            set(ax, 'XLim', limX(p,:), 'YLim', limZ(p,:));
            set(hVbar, 'XData', limX(p,:), 'YData', [0 0]);
            set(ax2, 'XLim', [0 tp(end)], ...
                     'YLim', [max(min(sqrt(sum(xp(1:3,:).^2,1))), 0.05) * 0.6, ...
                              max(sqrt(sum(xp(1:3,:).^2,1))) * 1.5]);
            set(ax3, 'XLim', [0 tp(end)], ...
                     'YLim', [min(xp(2,:)) - 1, max(xp(2,:)) + 1]);
            set(hud.title, 'String', phases(p).title);
            set(hHold, 'Visible', onoff(p >= 2));
        end

        set(hPath,  'XData', xp(1,1:i), 'YData', xp(3,1:i));
        set(hChase, 'XData', xp(1,i),   'YData', xp(3,i));
        rng_m = sqrt(sum(xp(1:3,1:i).^2, 1));
        set(hRng, 'XData', tp(1:i), 'YData', max(rng_m, 1e-3));
        set(hY,   'XData', tp(1:i), 'YData', xp(2,1:i));

        kInPhase = k - find(plan(1,:) == p, 1) + 1;
        flash = '';
        if kInPhase <= 14
            flash = phases(p).name;
        elseif p == 3 && k > nF - 14
            flash = 'DOCK';
        end

        rate = tp(end) / phases(p).screen;
        if rng_m(end) >= 1000
            rngStr = sprintf('%.2f km', rng_m(end)/1000);
        else
            rngStr = sprintf('%.2f m', rng_m(end));
        end
        hud_set(hud, {hms(tp(i)), rngStr, sprintf('%.3f m/s', dv{p}(i)), ...
                      sprintf('x %.0f', rate)}, ...
                {'PHASE TIME', 'RANGE', '\DeltaV USED', 'TIME RATE'}, flash);
    end
end

function s = onoff(tf)
if tf, s = 'on'; else, s = 'off'; end
end
