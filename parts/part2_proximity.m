function M = part2_proximity(C)
%PART2_PROXIMITY  Relative dynamics, hold acquisition and V-bar docking.
%
%   The Hohmann arrival of Part 1 is exact only on paper. A real ascent stage
%   arrives with a dispersion, so here the chaser is injected with a random
%   position and velocity error, allowed to drift, then flown to a 50 m V-bar
%   hold and finally walked into the docking port.
%
%   LVLH axes (non-standard, see PHI_HCW): x = along-track (V-bar),
%   y = cross-track, z = radial (R-bar).
%
%   Produces fig06..fig10 and fig19, and results/traj_part2.mat.

fprintf('\n===== PART 2 | PROXIMITY OPERATIONS =====================\n');
S = style();
n = C.n2;
T_MS = C.T2;

% --------------------------------------------------------- injection error --
% The seed is the reproducibility mechanism; the realisation itself is drawn,
% never frozen to a magic number.
rng(C.rngSeed);
ur = randn(3,1); ur = ur / norm(ur);
uv = randn(3,1); uv = uv / norm(uv);
Lrand = C.errPosRange(1) + diff(C.errPosRange) * rand();
Vrand = C.errVelRange(1) + diff(C.errVelRange) * rand();
dr0 = ur * Lrand;
dv0 = uv * Vrand;
dx0 = [dr0; dv0];

fprintf('Injection error (seed %d)\n', C.rngSeed);
fprintf('  dr0 = [%8.2f %8.2f %8.2f] m      |dr0| = %7.2f m\n', dr0, norm(dr0));
fprintf('  dv0 = [%8.4f %8.4f %8.4f] m/s    |dv0| = %7.4f m/s\n', dv0, norm(dv0));

% ------------------------------------------------------------- free drift ---
tD = linspace(0, C.nDriftOrbits * T_MS, 4000);
xD = zeros(6, numel(tD));
for k = 1:numel(tD)
    xD(:,k) = phi_hcw(tD(k), n) * dx0;
end
driftMax = max(sqrt(sum(xD(1:3,:).^2, 1)));
fprintf('Free drift over %d MS periods: max range %.2f km, final range %.2f km\n', ...
        C.nDriftOrbits, driftMax/1e3, norm(xD(1:3,end))/1e3);

% -------------------------------------------- two-impulse hold acquisition --
Hd = two_impulse_hold(dr0, dv0, C.r_hold, C.v_hold, C.dt_tr, n);
fprintf('Hold acquisition (dt_tr = %.1f s = 0.3 T_MS, rcond(Phi_rv) = %.2e)\n', ...
        Hd.dt_tr, Hd.rcond_Prv);
fprintf('  dV1 = [%7.4f %7.4f %7.4f] m/s   |dV1| = %.4f m/s\n', Hd.dV1, norm(Hd.dV1));
fprintf('  dV2 = [%7.4f %7.4f %7.4f] m/s   |dV2| = %.4f m/s\n', Hd.dV2, norm(Hd.dV2));
fprintf('  total %.4f m/s   arrival residuals: %.3e m, %.3e m/s\n', ...
        Hd.dV_total, Hd.err_pos, Hd.err_vel);

% ----------------------------------------------------- forced V-bar docking --
Dk = forced_vbar_docking(C.r_hold, C.v_hold, C.r_hold, C.N_legs, C.T_dock, n);
fprintf('Forced V-bar docking: %d legs of %.1f s\n', C.N_legs, Dk.dt);
fprintf('  per-leg |dV| = [%s] m/s\n', strtrim(sprintf('%.4f ', Dk.dV_each)));
fprintf('  total %.4f m/s   port residuals: %.3e m, %.3e m/s\n', ...
        Dk.dV_total, Dk.err_pos, Dk.err_vel);

% ------------------------------------------------------------ Monte Carlo ---
% The headline above is one draw. This samples the same error law 20 more
% times, state-transition-matrix only, on a private random stream so that the
% official rng(42) result is untouched whether or not this runs.
MCH = mc_hold(C, 20);
fprintf('Monte Carlo, %d draws of the same error law (STM only, private stream)\n', MCH.nDraw);
fprintf('  hold dV   P05 %.3f   P50 %.3f   P95 %.3f m/s   (official draw %.3f)\n', ...
        MCH.hold_p05, MCH.hold_p50, MCH.hold_p95, Hd.dV_total);
fprintf('  drift     P50 %.1f km  P95 %.1f km\n', MCH.drift_p50, MCH.drift_p95);
fprintf('  dock dV is draw-independent at %.4f m/s: the approach always starts\n', MCH.dock_p50);
fprintf('  from the hold point, so it is geometry, not dispersion.\n');

% ------------------------------------------------- nonlinear verification ---
mu_m  = C.muMoon * 1e9;        % km^3/s^2 -> m^3/s^2
R2_m  = C.R2 * 1e3;
[tN, XN] = ode45(@(t,x) bgnern_dynamics(t, x, n, R2_m, mu_m), ...
                 tD, dx0, C.odeWork);
xN = XN.';
dErr = sqrt(sum((xD(1:3,:) - xN(1:3,:)).^2, 1));
fprintf('HCW vs nonlinear BGNERM over %d periods: final separation %.2f m (%.3f %% of range)\n', ...
        C.nDriftOrbits, dErr(end), 100*dErr(end)/max(norm(xD(1:3,end)), eps));
fprintf('  close-range regime: rho/R2 = %.1e at the 50 m hold, so the linear\n', 50/R2_m);
fprintf('  model is exact to better than a millimetre where it is actually used.\n');

% ================================================================ FIGURES ==
% --- fig06 : free drift, 3-D ----------------------------------------------
fig = new_figure(1500, 950);
ax = axes('Parent', fig, 'Position', [0.10 0.10 0.82 0.80]);
style_axes(ax, sprintf('Free drift of the injection error over %d mothership orbits', ...
                       C.nDriftOrbits), ...
           'x  V-bar [km]', 'y  cross-track [km]', 'z  R-bar [km]');
plot3(ax, xD(1,:)/1e3, xD(2,:)/1e3, xD(3,:)/1e3, '-', 'Color', S.LM, 'LineWidth', 1.8);
plot3(ax, 0, 0, 0, 's', 'MarkerSize', 13, 'MarkerFaceColor', S.MS, 'MarkerEdgeColor','none');
plot3(ax, xD(1,1)/1e3, xD(2,1)/1e3, xD(3,1)/1e3, 'o', 'MarkerSize', 10, ...
      'MarkerFaceColor', S.transfer, 'MarkerEdgeColor','none');
plot3(ax, xD(1,end)/1e3, xD(2,end)/1e3, xD(3,end)/1e3, 'p', 'MarkerSize', 15, ...
      'MarkerFaceColor', S.warn, 'MarkerEdgeColor','none');
legend(ax, {'relative trajectory','mothership (origin)','injection','after 3 orbits'}, ...
       'TextColor', S.text, 'Color', S.panel, 'EdgeColor', S.dim, ...
       'Location','northeast','FontSize', S.fsSmall);
view(ax, 40, 22); grid(ax,'on'); box(ax,'off');
M.fig06 = save_fig(fig, 'fig06_free_drift_3d', C);

% --- fig07 : components ---------------------------------------------------
fig = new_figure(1600, 1000);
lbl = {'x  along-track (V-bar) [km]', 'y  cross-track [km]', 'z  radial (R-bar) [km]'};
for k = 1:3
    ax = subplot(3,1,k,'Parent',fig);
    style_axes(ax, lbl{k}, '', '');
    plot(ax, tD/T_MS, xD(k,:)/1e3, '-', 'Color', S.LM, 'LineWidth', 1.8);
    if k == 3, xlabel(ax, 'time [mothership orbits]', 'Color', S.dim); end
    xlim(ax, [0 C.nDriftOrbits]);
end
annotation(fig,'textbox',[0.02 0.955 0.96 0.04],'String', ...
    sprintf(['Free drift components  |  along-track drift is secular, ' ...
             'cross-track is a bounded harmonic  |  |dr_0| = %.1f m, |dv_0| = %.3f m/s'], ...
             norm(dr0), norm(dv0)), ...
    'Color', S.text,'EdgeColor','none','FontSize', S.fsAxis,'FontName',S.font, ...
    'HorizontalAlignment','center');
M.fig07 = save_fig(fig, 'fig07_free_drift_components', C);

% --- fig19 : two-impulse hold acquisition ---------------------------------
fig = new_figure(1600, 850);
ax = axes('Parent', fig, 'Position', [0.07 0.13 0.42 0.74]);
style_axes(ax, 'Hold acquisition, in-plane path', 'x  V-bar [m]', 'z  R-bar [m]');
plot(ax, Hd.x(1,:), Hd.x(3,:), '-', 'Color', S.transfer, 'LineWidth', 2.0);
plot(ax, dr0(1), dr0(3), 'o', 'MarkerSize', 11, 'MarkerFaceColor', S.LM, 'MarkerEdgeColor','none');
plot(ax, C.r_hold(1), C.r_hold(3), 'd', 'MarkerSize', 12, 'MarkerFaceColor', S.hold, 'MarkerEdgeColor','none');
plot(ax, 0, 0, 's', 'MarkerSize', 12, 'MarkerFaceColor', S.MS, 'MarkerEdgeColor','none');
text(ax, dr0(1), dr0(3), '  injection', 'Color', S.LM, 'FontSize', S.fsSmall);
text(ax, C.r_hold(1), C.r_hold(3), '  hold 50 m', 'Color', S.hold, 'FontSize', S.fsSmall);
axis(ax,'equal');

ax2 = axes('Parent', fig, 'Position', [0.57 0.13 0.40 0.74]);
style_axes(ax2, 'Range to the hold point', 'time [s]', 'range [m]');
set(ax2, 'YScale', 'log');       % semilogy on a held axes would not do it
rr = sqrt(sum((Hd.x(1:3,:) - C.r_hold).^2, 1));
semilogy(ax2, Hd.t, max(rr,1e-6), '-', 'Color', S.hold, 'LineWidth', 2.0);
xlim(ax2, [0 Hd.dt_tr]);
annotation(fig,'textbox',[0.02 0.93 0.96 0.05],'String', ...
    sprintf(['Two-impulse HCW targeting  |  \\DeltaV_1 = %.3f m/s, ' ...
             '\\DeltaV_2 = %.3f m/s, total %.3f m/s over %.0f s'], ...
             norm(Hd.dV1), norm(Hd.dV2), Hd.dV_total, Hd.dt_tr), ...
    'Color', S.text,'EdgeColor','none','FontSize', S.fsAxis,'FontName',S.font, ...
    'HorizontalAlignment','center');
M.fig19 = save_fig(fig, 'fig19_two_impulse_hold', C);

% --- fig08 : forced V-bar docking -----------------------------------------
fig = new_figure(1600, 1000);
ax = axes('Parent', fig, 'Position', [0.09 0.58 0.86 0.33]);
style_axes(ax, 'Forced straight-line V-bar approach', 'time [s]', 'position [m]');
plot(ax, Dk.t, Dk.x(1,:), '-', 'Color', S.hold, 'LineWidth', 2.2);
plot(ax, Dk.t, Dk.x(3,:), '-', 'Color', S.LM, 'LineWidth', 2.0);
for k = 1:numel(Dk.t_impulse)
    plot(ax, Dk.t_impulse(k)*[1 1], [min(Dk.x(3,:))-2 55], ':', 'Color', S.dim);
end
legend(ax, {'x  V-bar','z  R-bar'}, 'TextColor', S.text, 'Color', S.panel, ...
       'EdgeColor', S.dim, 'Location','northeast','FontSize', S.fsSmall);
xlim(ax, [0 Dk.T_total]);

ax2 = axes('Parent', fig, 'Position', [0.09 0.09 0.86 0.36]);
style_axes(ax2, 'In-plane path: 50 m hold to docking port', 'x  V-bar [m]', 'z  R-bar [m]');
plot(ax2, Dk.x(1,:), Dk.x(3,:), '-', 'Color', S.dock, 'LineWidth', 2.2);
plot(ax2, Dk.waypoints(1,:), Dk.waypoints(3,:), 'o', 'MarkerSize', 8, ...
     'MarkerFaceColor', S.transfer, 'MarkerEdgeColor','none');
plot(ax2, C.r_hold(1), C.r_hold(3), 'd', 'MarkerSize', 13, 'MarkerFaceColor', S.hold, 'MarkerEdgeColor','none');
plot(ax2, 0, 0, 's', 'MarkerSize', 14, 'MarkerFaceColor', S.MS, 'MarkerEdgeColor','none');
text(ax2, C.r_hold(1), C.r_hold(3), ' hold', 'Color', S.hold, 'FontSize', S.fsSmall, ...
     'HorizontalAlignment','right');
text(ax2, 0, 0, ' port ', 'Color', S.MS, 'FontSize', S.fsSmall, 'HorizontalAlignment','left');
xlim(ax2, [-4 56]);
annotation(fig,'textbox',[0.02 0.955 0.96 0.04],'String', ...
    sprintf('%d legs x %.0f s + braking impulse  |  \\DeltaV_{dock} = %.4f m/s', ...
            C.N_legs, Dk.dt, Dk.dV_total), ...
    'Color', S.text,'EdgeColor','none','FontSize', S.fsAxis,'FontName',S.font, ...
    'HorizontalAlignment','center');
M.fig08 = save_fig(fig, 'fig08_forced_vbar_docking', C);

% --- fig09 : linear vs nonlinear, 3-D -------------------------------------
fig = new_figure(1500, 950);
ax = axes('Parent', fig, 'Position', [0.10 0.10 0.82 0.80]);
style_axes(ax, 'Linear HCW (solid) vs nonlinear BGNERM (dashed)', ...
           'x  V-bar [km]', 'y  cross-track [km]', 'z  R-bar [km]');
plot3(ax, xD(1,:)/1e3, xD(2,:)/1e3, xD(3,:)/1e3, '-', 'Color', S.LM, 'LineWidth', 2.0);
plot3(ax, xN(1,:)/1e3, xN(2,:)/1e3, xN(3,:)/1e3, '--', 'Color', S.warn, 'LineWidth', 2.0);
plot3(ax, 0, 0, 0, 's', 'MarkerSize', 13, 'MarkerFaceColor', S.MS, 'MarkerEdgeColor','none');
legend(ax, {'HCW (STM)','BGNERM (ode45)','mothership'}, 'TextColor', S.text, ...
       'Color', S.panel, 'EdgeColor', S.dim, 'Location','northeast','FontSize', S.fsSmall);
view(ax, 40, 22);
M.fig09 = save_fig(fig, 'fig09_hcw_vs_bgnern_3d', C);

% --- fig10 : model error --------------------------------------------------
fig = new_figure(1600, 800);
ax = axes('Parent', fig, 'Position', [0.09 0.13 0.87 0.75]);
style_axes(ax, 'Linearisation error |r_{HCW} - r_{BGNERM}|', ...
           'time [mothership orbits]', 'error [m]');
set(ax, 'YScale', 'log');
semilogy(ax, tD/T_MS, max(dErr,1e-3), '-', 'Color', S.J2, 'LineWidth', 2.0);
yline(ax, 50, ':', 'hold-point scale (50 m)', 'Color', S.hold, 'FontSize', S.fsSmall, ...
      'LabelHorizontalAlignment','left', 'LineWidth', 1.5);
xlim(ax, [0 C.nDriftOrbits]);
ylim(ax, [1e-3 max(dErr)*3]);      % the curve starts from an exact zero
M.fig10 = save_fig(fig, 'fig10_hcw_bgnern_error', C);

% ================================================================ OUTPUTS ==
traj = struct('t_drift', tD, 'x_hcw', xD, 'x_nl', xN, 'err_nl', dErr, ...
              't_hold', Hd.t, 'x_hold', Hd.x, ...
              't_dock', Dk.t, 'x_dock', Dk.x, ...
              'dx0', dx0, 'r_hold', C.r_hold, ...
              'dV_hold_1', Hd.dV1, 'dV_hold_2', Hd.dV2, ...
              'dock_impulses', Dk.impulses, 'dock_t_impulse', Dk.t_impulse, ...
              'dock_waypoints', Dk.waypoints, 'T_MS', T_MS, 'n', n); %#ok<NASGU>
save(fullfile(C.resDir, 'traj_part2.mat'), '-struct', 'traj');

M.dr0 = dr0;  M.dv0 = dv0;
M.dr0_norm_m  = norm(dr0);
M.dv0_norm_ms = norm(dv0);
M.drift_max_km = driftMax/1e3;
M.dV_hold_ms  = Hd.dV_total;
M.dV_dock_ms  = Dk.dV_total;
M.dV_prox_ms  = Hd.dV_total + Dk.dV_total;
M.hold_err_pos_m = Hd.err_pos;
M.hold_err_vel_ms = Hd.err_vel;
M.dock_err_pos_m = Dk.err_pos;
M.dock_err_vel_ms = Dk.err_vel;
M.nl_final_sep_m = dErr(end);
M.dt_tr_s = Hd.dt_tr;
M.mc_nDraw     = MCH.nDraw;
M.mc_hold_p05  = MCH.hold_p05;
M.mc_hold_p50  = MCH.hold_p50;
M.mc_hold_p95  = MCH.hold_p95;
M.mc_drift_p50 = MCH.drift_p50;
M.mc_drift_p95 = MCH.drift_p95;
M.mc_dock_p50  = MCH.dock_p50;

fprintf('Part 2 complete: 6 figures written.\n');
end
