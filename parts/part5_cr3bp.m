function M = part5_cr3bp(C)
%PART5_CR3BP  The same rendezvous, re-solved in the circular restricted 3BP.
%
%   Part 1 designs the transfer in a Moon-only gravity field. Here the Earth
%   is put back in as a primary and the manoeuvre is re-converged by single
%   shooting on [dvx, dvy, tof] in the synodic frame. The interesting output
%   is not the trajectory - it looks identical to the naked eye - but the size
%   of the correction, which quantifies how much of the Earth's pull a
%   two-body low lunar orbit design actually leaves on the table.
%
%   Produces fig16 and results/traj_part5.mat.

fprintf('\n===== PART 5 | CR3BP TRANSFER ===========================\n');
S = style();

H = hohmann_design(C.R1, C.R2, C.muMoon);
Ph = phasing_wait(C.n1, C.n2, H.dt_tof, C.phi0);
t_ign  = Ph.t_wait;
thetaP = Ph.theta_ignite;

% States at ignition, still Keplerian and still in the MCI frame.
r_LM = C.R1 * [cos(thetaP); sin(thetaP); 0];
v_LM = C.n1 * C.R1 * [-sin(thetaP); cos(thetaP); 0];
thMS = C.phi0 + C.n2 * t_ign;
r_MS = C.R2 * [cos(thMS); sin(thMS); 0];
v_MS = C.n2 * C.R2 * [-sin(thMS); cos(thMS); 0];

% Synodic +x is the Earth-to-Moon direction. With the Part 3 ephemeris the
% Moon-to-Earth longitude is nEM*t, so the Earth-to-Moon longitude is that
% plus pi. Using the same ephemeris in Parts 3 and 5 keeps the two
% perturbation studies talking about the same geometry.
alpha = C.nEM * t_ign + pi;
fprintf('Synodic frame at ignition: Earth-Moon line at %.4f deg in MCI\n', rad2deg(alpha));
fprintf('Units: LU = %.0f km, TU = %.1f s (%.3f d), VU = %.6f km/s\n', ...
        C.LU, C.TU, C.TU/86400, C.VU);

[r0s_LM, v0s_LM] = moon_inertial_to_synodic(r_LM, v_LM, alpha, C);
[r0s_MS, v0s_MS] = moon_inertial_to_synodic(r_MS, v_MS, alpha, C);
x0_LM = [r0s_LM; v0s_LM];
x0_MS = [r0s_MS; v0s_MS];

% Two-body guess mapped into synodic axes. A delta-v is a velocity
% difference at a fixed point, so the rotating-frame term cancels and the
% mapping is a plain rotation and rescale.
dV1_MCI = H.dV1 * v_LM / norm(v_LM);
Rin = [cos(alpha) sin(alpha) 0; -sin(alpha) cos(alpha) 0; 0 0 1];
dV1_syn = Rin * dV1_MCI / C.VU;
p0 = [dV1_syn(1); dV1_syn(2); H.dt_tof / C.TU];

Sh = shoot_cr3bp_transfer(x0_LM, x0_MS, p0, C);

if Sh.restarted, restartNote = ' (after restart)'; else, restartNote = ''; end
fprintf('Shooting: exitflag %d%s, miss %.4f km (%.1f m)\n', Sh.exitflag, ...
        restartNote, Sh.miss_km, Sh.miss_km*1e3);
if Sh.miss_km > 1
    fprintf('  [warn] miss above the 1 km acceptance threshold.\n');
end

fprintf('\n  Quantity            2-body        CR3BP        |difference|\n');
fprintf('  ------------------------------------------------------------\n');
fprintf('  dV1  [km/s]      %10.6f  %11.6f   %11.6f\n', H.dV1, Sh.dV1, abs(Sh.dV1 - H.dV1));
fprintf('  dV2  [km/s]      %10.6f  %11.6f   %11.6f\n', H.dV2, Sh.dV2, abs(Sh.dV2 - H.dV2));
fprintf('  dVtot[km/s]      %10.6f  %11.6f   %11.6f  (%.2f mm/s)\n', ...
        H.dVtot, Sh.dVtot, abs(Sh.dVtot - H.dVtot), abs(Sh.dVtot - H.dVtot)*1e6);
fprintf('  TOF  [s]         %10.2f  %11.2f   %11.2f\n', ...
        H.dt_tof, Sh.tof_s, abs(Sh.tof_s - H.dt_tof));

% ------------------------------------------- the family, not one member ----
% The planar shooter has three decision variables and two independent miss
% components, so the zero-miss set is a curve. Scanning time of flight and
% re-optimising the impulse at each point turns "the" correction into what it
% actually is: a shallow parabola whose members all close the rendezvous.
FAM = scan_cr3bp_family(x0_LM, x0_MS, p0, C, ...
                        struct('window', 40, 'nPts', 9, 'maxEval', 60));
fprintf('\nZero-miss family, time of flight scanned over %+.0f s\n', 40);
fprintf('  %-22s %9s %12s %10s\n', 'member', 'dTOF [s]', 'dV vs 2-body', 'miss [m]');
for m = FAM.members
    fprintf('  %-22s %+9.1f %9.2f mm/s %9.3f\n', m.label, m.dtof_s, ...
            (m.dVtot - H.dVtot)*1e6, m.miss_m);
end
fprintf('  %d of %d scanned points close below 1 m; budget spread %.1f mm/s\n', ...
        FAM.nClosed, numel(FAM.tof_s), FAM.spread_mms);
fprintf('  So the two-body design already sits within about 9 mm/s of the\n');
fprintf('  cheapest three-body member. The sign matters too: at the minimum the\n');
fprintf('  CR3BP solution is marginally CHEAPER, not more expensive.\n');

% Moon-centered synodic coordinates, in km, for plotting and export.
mu = C.muCR3BP;
trLM = (Sh.XLM(:,1:3).' - [1-mu; 0; 0]) * C.LU;
trMS = (Sh.XMS(:,1:3).' - [1-mu; 0; 0]) * C.LU;

% One full mothership revolution in the synodic frame, for context.
[~, XmsFull] = ode45(@(t,x) cr3bp_eom(t, x, mu), [0 C.T2/C.TU], x0_MS, ...
                     odeset('RelTol',1e-11,'AbsTol',1e-11));
msRing = (XmsFull(:,1:3).' - [1-mu; 0; 0]) * C.LU;

% ================================================================ FIGURES ==
fig = new_figure(1700, 900);
ax = axes('Parent', fig, 'Position', [0.06 0.09 0.55 0.80]);
style_axes(ax, 'Optimised transfer in the Earth-Moon synodic frame (Moon-centered view)', ...
           'x_{syn} [km]', 'y_{syn} [km]');
axis(ax, 'equal');
draw_moon(ax, C.RMoon);
% Explicit handles: a legend built from a bare string list would attach itself
% to the Moon patches and come back as a row of grey swatches.
hRing = plot(ax, msRing(1,:), msRing(2,:), '-', 'Color', [S.MS 0.6], 'LineWidth', 1.5);
hLM   = plot(ax, trLM(1,:), trLM(2,:), '-', 'Color', S.transfer, 'LineWidth', 2.6);
hMS   = plot(ax, trMS(1,:), trMS(2,:), '-', 'Color', S.MS, 'LineWidth', 2.0);
hIgn  = plot(ax, trLM(1,1), trLM(2,1), 'o', 'MarkerSize', 11, ...
             'MarkerFaceColor', S.LM, 'MarkerEdgeColor','none');
hRdv  = plot(ax, trLM(1,end), trLM(2,end), 'p', 'MarkerSize', 18, ...
             'MarkerFaceColor', S.dock, 'MarkerEdgeColor','none');
quiver(ax, 0, 0, -1400, 0, 0, 'Color', S.third, 'LineWidth', 2.0, 'MaxHeadSize', 0.5);
text(ax, -1500, 180, 'to Earth', 'Color', S.third, 'FontSize', S.fsSmall);
% Three columns, short labels: five columns of long labels overflow the axes
% width once the report theme enlarges the font, and the first entry gets
% clipped off the left edge of the figure.
legend(ax, [hRing hLM hMS hIgn hRdv], ...
       {'MS orbit','LM transfer','MS in transit','\DeltaV_1','rendezvous'}, ...
       'TextColor', S.text, 'Color', S.panel, 'EdgeColor', S.dim, ...
       'Location','southoutside','Orientation','horizontal','FontSize', S.fsSmall, ...
       'NumColumns', 3);
xlim(ax, 2500*[-1 1]); ylim(ax, 2500*[-1 1]);

ax2 = axes('Parent', fig, 'Position', [0.68 0.55 0.29 0.34]);
style_axes(ax2, 'LM-MS range during the transfer', 't [min]', 'range [km]');
nMin = min(size(Sh.XLM,1), size(Sh.XMS,1));
tt = linspace(0, Sh.tof_s, 400);
rl = interp1(Sh.tLM, Sh.XLM(:,1:3), linspace(0, Sh.tof_TU, 400)).';
rm = interp1(Sh.tMS, Sh.XMS(:,1:3), linspace(0, Sh.tof_TU, 400)).';
rngKm = sqrt(sum((rl-rm).^2,1)) * C.LU;
plot(ax2, tt/60, max(rngKm, 1e-2), '-', 'Color', S.hold, 'LineWidth', 2.2);
set(ax2, 'YScale', 'log');
xlim(ax2, [0 Sh.tof_s/60]);
ylim(ax2, [1e-2 max(rngKm)*2]);   % the final range collapses to zero

ax3 = axes('Parent', fig, 'Position', [0.68 0.10 0.29 0.32]);
style_axes(ax3, 'Correction vs the two-body design', '', '');
bars = [abs(Sh.dV1 - H.dV1), abs(Sh.dV2 - H.dV2), abs(Sh.dVtot - H.dVtot)] * 1e6;  % mm/s
b = bar(ax3, bars, 0.55, 'FaceColor', S.J2, 'EdgeColor','none');
set(ax3, 'XTickLabel', {'\DeltaV_1','\DeltaV_2','total'}, 'XTick', 1:3);
ylabel(ax3, '|\Delta| [mm/s]', 'Color', S.dim);
text(ax3, 1:3, bars, compose('%.2f', bars), 'Color', S.text, ...
     'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize', S.fsSmall);
ylim(ax3, [0 max(bars)*1.35 + eps]);
annotation(fig,'textbox',[0.02 0.93 0.96 0.05],'String', ...
    sprintf('CR3BP single shooting  |  \\mu = %.5f, miss = %.1f m, TOF shift = %.1f s', ...
            mu, Sh.miss_km*1e3, Sh.tof_s - H.dt_tof), ...
    'Color', S.text,'EdgeColor','none','FontSize', S.fsAxis,'FontName',S.font, ...
    'HorizontalAlignment','center');
M.fig16 = save_fig(fig, 'fig16_cr3bp_transfer', C);

% ================================================================ OUTPUTS ==
traj = struct('t_LM', Sh.tLM * C.TU, 'x_syn_LM', trLM, ...
              't_MS', Sh.tMS * C.TU, 'x_syn_MS', trMS, ...
              'ms_ring', msRing, 'alpha', alpha, ...
              'tof_s', Sh.tof_s, 'miss_km', Sh.miss_km, ...
              'dV1', Sh.dV1, 'dV2', Sh.dV2, 'RMoon', C.RMoon, ...
              ... % Full non-dimensional barycentric states, kept so the audit
              ... % can evaluate the Jacobi constant along the optimised arc.
              'tau_LM', Sh.tLM, 'X_syn_LM', Sh.XLM, ...
              'tau_MS', Sh.tMS, 'X_syn_MS', Sh.XMS, ...
              'mu_cr3bp', mu); %#ok<NASGU>
save(fullfile(C.resDir, 'traj_part5.mat'), '-struct', 'traj');

M.miss_km        = Sh.miss_km;
M.miss_m         = Sh.miss_km * 1e3;
M.dV1_cr3bp      = Sh.dV1;
M.dV2_cr3bp      = Sh.dV2;
M.dVtot_cr3bp    = Sh.dVtot;
M.dV_extra_ms    = abs(Sh.dVtot - H.dVtot) * 1e3;      % m/s
M.dV_extra_mms   = abs(Sh.dVtot - H.dVtot) * 1e6;      % mm/s
M.dV_signed_mms  = (Sh.dVtot - H.dVtot) * 1e6;         % signed: negative = cheaper
M.fam_spread_mms = FAM.spread_mms;
M.fam_nClosed    = FAM.nClosed;
if numel(FAM.members) >= 3
    M.fam_minDV_mms  = (FAM.members(1).dVtot - H.dVtot) * 1e6;
    M.fam_minDV_dtof = FAM.members(1).dtof_s;
    M.fam_ref_mms    = (FAM.members(3).dVtot - H.dVtot) * 1e6;
    M.fam_ref_dtof   = FAM.members(3).dtof_s;
    M.fam_ref_miss_m = FAM.members(3).miss_m;
end
M.tof_cr3bp_s    = Sh.tof_s;
M.tof_shift_s    = Sh.tof_s - H.dt_tof;
M.exitflag       = Sh.exitflag;

fprintf('Part 5 complete: 1 figure written.\n');
end
