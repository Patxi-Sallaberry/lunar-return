function M = part1_orbital_transfer(C)
%PART1_ORBITAL_TRANSFER  Phasing, Hohmann climb and Keplerian verification.
%
%   The lunar module sits on a 100 km circular orbit, waits for the phasing
%   window, burns tangentially into a Hohmann ellipse and meets the mothership
%   on its 400 km circular orbit half an ellipse later. Everything is then
%   re-derived in closed form and the two solutions are differenced, which is
%   what turns "the plot looks right" into a number.
%
%   Produces fig01..fig05 and results/traj_part1.mat.

fprintf('\n===== PART 1 | ORBITAL TRANSFER =========================\n');
S = style();

% ------------------------------------------------------------ design ------
H = hohmann_design(C.R1, C.R2, C.muMoon);
P = phasing_wait(C.n1, C.n2, H.dt_tof, C.phi0);

theta_p = P.theta_ignite;                 % LM argument of latitude at ignition
t_burn1 = P.t_wait;
t_arr   = P.t_wait + H.dt_tof;
t_end   = t_arr + 0.25 * C.T2;            % short outer coast, for fig05

fprintf('Transfer ellipse   a = %10.3f km    e = %.6f\n', H.a, H.e);
fprintf('Circular speeds    vc1 = %.4f km/s   vc2 = %.4f km/s\n', H.vc1, H.vc2);
fprintf('Ellipse speeds     vpe = %.4f km/s   vap = %.4f km/s\n', H.vpe, H.vap);
fprintf('Impulses           dV1 = %7.2f m/s   dV2 = %7.2f m/s   total = %7.2f m/s\n', ...
        H.dV1_ms, H.dV2_ms, H.dVtot_ms);
fprintf('Time of flight     %.2f s (%.2f min)\n', H.dt_tof, H.dt_tof/60);
fprintf('Required lead      %.4f deg   available at t=0: %.4f deg\n', ...
        P.dtheta_H_deg, rad2deg(C.phi0));
fprintf('Phasing wait       %.1f s (%.3f h)   total mission %.3f h\n', ...
        P.t_wait, P.t_wait_h, P.t_mission_h);

% -------------------------------------------------- numerical propagation --
x0_LM = [C.R1; 0; 0; 0; H.vc1; 0];
x0_MS = [C.R2*cos(C.phi0); C.R2*sin(C.phi0); 0; ...
         -C.n2*C.R2*sin(C.phi0); C.n2*C.R2*cos(C.phi0); 0];

tA = linspace(0, t_burn1, 4000);
tB = linspace(t_burn1, t_arr, 2500);
tC = linspace(t_arr, t_end, 800);

f2b = @(t,x) fr2b(t, x, C.muMoon);

[~, XA] = ode45(f2b, tA, x0_LM, C.odeTight);

% Burn 1: tangential, along the instantaneous velocity.
xb = XA(end, :).';
vh = xb(4:6) / norm(xb(4:6));
dV1_vec = H.dV1 * vh;
xb(4:6) = xb(4:6) + dV1_vec;

[~, XB] = ode45(f2b, tB, xb, C.odeTight);

% Burn 2 at apoapsis: circularise so the constants of motion show a third
% plateau instead of stopping mid-transfer.
xc = XB(end, :).';
vh2 = xc(4:6) / norm(xc(4:6));
dV2_vec = H.dV2 * vh2;
xc(4:6) = xc(4:6) + dV2_vec;

[~, XC] = ode45(f2b, tC, xc, C.odeTight);

t_all = [tA, tB(2:end), tC(2:end)];
X_LM  = [XA; XB(2:end,:); XC(2:end,:)].';
rLM = X_LM(1:3,:);  vLM = X_LM(4:6,:);

[~, XMS] = ode45(f2b, t_all, x0_MS, C.odeTight);
X_MS = XMS.';
rMS = X_MS(1:3,:);  vMS = X_MS(4:6,:);

% ------------------------------------------------ analytical propagation ---
legA = struct('type','circular','R',C.R1,'n',C.n1,'theta0',0,'t0',0);
legB = struct('type','ellipse','a',H.a,'e',H.e,'mu',C.muMoon, ...
              't0',t_burn1,'omega',theta_p);
legC = struct('type','circular','R',C.R2,'n',C.n2, ...
              'theta0',theta_p+pi,'t0',t_arr);
legMS = struct('type','circular','R',C.R2,'n',C.n2,'theta0',C.phi0,'t0',0);

[rA_an, vA_an] = analytical_kepler_state(tA, legA);
[rB_an, vB_an] = analytical_kepler_state(tB, legB);
[rC_an, vC_an] = analytical_kepler_state(tC, legC);
rLM_an = [rA_an, rB_an(:,2:end), rC_an(:,2:end)];
vLM_an = [vA_an, vB_an(:,2:end), vC_an(:,2:end)];

[rMS_an, vMS_an] = analytical_kepler_state(t_all, legMS);

errLM  = sqrt(sum((rLM - rLM_an).^2, 1)) * 1e3;             % m
errMS  = sqrt(sum((rMS - rMS_an).^2, 1)) * 1e3;
dnum   = rLM - rMS;
dan    = rLM_an - rMS_an;
errRel = sqrt(sum((dnum - dan).^2, 1)) * 1e3;

iArr = numel(tA) + numel(tB) - 1;                           % index of arrival
missNum = norm(rLM(:,iArr) - rMS(:,iArr)) * 1e3;            % m
missAn  = norm(rLM_an(:,iArr) - rMS_an(:,iArr)) * 1e3;

fprintf('\nNumerical vs analytical (max over the full timeline):\n');
fprintf('  LM position error        %9.3e m\n', max(errLM));
fprintf('  MS position error        %9.3e m\n', max(errMS));
fprintf('  relative vector error    %9.3e m\n', max(errRel));
fprintf('  rendezvous miss (num)    %9.3e m   (analytical %9.3e m)\n', missNum, missAn);

% -------------------------------------------------- constants of motion ----
rn = sqrt(sum(rLM.^2,1));
vn = sqrt(sum(vLM.^2,1));
epsSpec = vn.^2/2 - C.muMoon./rn;
hVec = cross(rLM, vLM, 1);
hMag = sqrt(sum(hVec.^2,1));
eVec = ((vn.^2 - C.muMoon./rn) .* rLM - sum(rLM.*vLM,1) .* vLM) / C.muMoon;
eMag = sqrt(sum(eVec.^2,1));

iA = 1:numel(tA);
iB = numel(tA)+1 : numel(tA)+numel(tB)-1;
iC = numel(tA)+numel(tB) : numel(t_all);

fprintf('\n  Leg                     e        |h| [km^2/s]    eps [km^2/s^2]\n');
fprintf('  ---------------------------------------------------------------\n');
fprintf('  inner circular   %10.6f   %12.2f   %14.5f\n', mean(eMag(iA)), mean(hMag(iA)), mean(epsSpec(iA)));
fprintf('  transfer ellipse %10.6f   %12.2f   %14.5f\n', mean(eMag(iB)), mean(hMag(iB)), mean(epsSpec(iB)));
fprintf('  outer circular   %10.6f   %12.2f   %14.5f\n', mean(eMag(iC)), mean(hMag(iC)), mean(epsSpec(iC)));

% ================================================================ FIGURES ==
% --- fig01 : mission timeline --------------------------------------------
fig = new_figure(1600, 640);
ax = axes('Parent', fig, 'Position', [0.07 0.28 0.88 0.50]);
style_axes(ax, 'Mission timeline (Moon-centered inertial)', 'time [h]', '');
segs = {'phasing coast', 'Hohmann transfer', 'outer coast'};
cols = [S.LM; S.transfer; S.MS];
tb   = [0 t_burn1; t_burn1 t_arr; t_arr t_end] / 3600;
for k = 1:3
    patch(ax, [tb(k,1) tb(k,2) tb(k,2) tb(k,1)], [0.2 0.2 0.8 0.8], cols(k,:), ...
          'EdgeColor','none','FaceAlpha',0.75);
    text(ax, mean(tb(k,:)), 0.5, segs{k}, 'Color', [0.05 0.07 0.10], ...
         'HorizontalAlignment','center','FontWeight','bold','FontSize', S.fsSmall);
end
for e = [t_burn1 t_arr]/3600
    plot(ax, [e e], [0.05 0.95], '--', 'Color', S.dock, 'LineWidth', 1.2);
end
text(ax, t_burn1/3600, 1.02, sprintf('  \\DeltaV_1 = %.1f m/s', H.dV1_ms), ...
     'Color', S.dock, 'FontSize', S.fsSmall, 'VerticalAlignment','bottom');
text(ax, t_arr/3600, 1.02, sprintf('  \\DeltaV_2 = %.1f m/s (rendezvous)', H.dV2_ms), ...
     'Color', S.dock, 'FontSize', S.fsSmall, 'VerticalAlignment','bottom');
ylim(ax, [0 1.25]); xlim(ax, [0 t_end/3600]);
set(ax, 'YTick', []);
M.fig01 = save_fig(fig, 'fig01_mission_timeline', C);

% --- fig02 : geometry, t = 0 and at ignition ------------------------------
fig = new_figure(1700, 850);
for panel = 1:2
    ax = subplot(1, 2, panel, 'Parent', fig);
    if panel == 1
        ttl = sprintf('t = 0 : MS leads by \\phi_0 = %.0f\\circ', rad2deg(C.phi0));
        thLM = 0;  thMS = C.phi0;
    else
        ttl = sprintf('t = t_{wait} = %.2f h : ignition geometry', P.t_wait_h);
        thLM = theta_p;  thMS = C.phi0 + C.n2*t_burn1;
    end
    style_axes(ax, ttl, 'x [km]', 'y [km]');
    axis(ax, 'equal');
    draw_moon(ax, C.RMoon);

    th = linspace(0, 2*pi, 721);
    plot(ax, C.R1*cos(th), C.R1*sin(th), '-',  'Color', [S.LM 0.55], 'LineWidth', 1.4);
    plot(ax, C.R2*cos(th), C.R2*sin(th), '-',  'Color', [S.MS 0.55], 'LineWidth', 1.4);

    if panel == 2
        nu = linspace(0, pi, 400);
        rr = H.p ./ (1 + H.e*cos(nu));
        plot(ax, rr.*cos(nu+theta_p), rr.*sin(nu+theta_p), '--', ...
             'Color', S.transfer, 'LineWidth', 2.2);
        rArr = C.R2*[cos(theta_p+pi); sin(theta_p+pi)];
        plot(ax, rArr(1), rArr(2), 'p', 'MarkerSize', 16, ...
             'MarkerFaceColor', S.transfer, 'MarkerEdgeColor','none');
        text(ax, rArr(1), rArr(2), '  rendezvous', 'Color', S.transfer, 'FontSize', S.fsSmall);
    end

    plot(ax, C.R1*cos(thLM), C.R1*sin(thLM), 'o', 'MarkerSize', 11, ...
         'MarkerFaceColor', S.LM, 'MarkerEdgeColor','none');
    plot(ax, C.R2*cos(thMS), C.R2*sin(thMS), 's', 'MarkerSize', 12, ...
         'MarkerFaceColor', S.MS, 'MarkerEdgeColor','none');
    text(ax, C.R1*cos(thLM), C.R1*sin(thLM), '  LM', 'Color', S.LM, 'FontSize', S.fsSmall);
    text(ax, C.R2*cos(thMS), C.R2*sin(thMS), '  MS', 'Color', S.MS, 'FontSize', S.fsSmall);
    xlim(ax, 2400*[-1 1]); ylim(ax, 2400*[-1 1]);
end
annotation(fig, 'textbox', [0.02 0.94 0.96 0.05], 'String', ...
    sprintf(['Hohmann geometry  |  R_1 = %.1f km, R_2 = %.1f km, ' ...
             '\\DeltaV_{tot} = %.2f m/s, TOF = %.1f min'], ...
             C.R1, C.R2, H.dVtot_ms, H.dt_tof/60), ...
    'Color', S.text, 'EdgeColor','none', 'FontSize', S.fsAxis + 2, ...
    'FontName', S.font, 'HorizontalAlignment','center', 'FitBoxToText','off');
M.fig02 = save_fig(fig, 'fig02_hohmann_geometry', C);

% --- fig03 : numerical vs analytical --------------------------------------
fig = new_figure(1700, 900);
ax = axes('Parent', fig, 'Position', [0.08 0.09 0.60 0.82]);
style_axes(ax, 'Propagated trajectories: ode45 (solid) vs closed-form Kepler (dots)', ...
           'x [km]', 'y [km]');
axis(ax, 'equal');
draw_moon(ax, C.RMoon);
% Explicit handles: a bare string list would bind to the Moon patches first.
h1 = plot(ax, rLM(1,:), rLM(2,:), '-', 'Color', S.LM, 'LineWidth', 2.0);
h2 = plot(ax, rMS(1,:), rMS(2,:), '-', 'Color', S.MS, 'LineWidth', 1.6);
k = 1:60:numel(t_all);
h3 = plot(ax, rLM_an(1,k), rLM_an(2,k), '.', 'Color', S.text, 'MarkerSize', 7);
h4 = plot(ax, rMS_an(1,k), rMS_an(2,k), '.', 'Color', S.dim,  'MarkerSize', 7);
h5 = plot(ax, rLM(1,iB(1)), rLM(2,iB(1)), 'o', 'MarkerSize', 10, ...
          'MarkerFaceColor', S.transfer, 'MarkerEdgeColor','none');
h6 = plot(ax, rLM(1,iArr),  rLM(2,iArr),  'p', 'MarkerSize', 16, ...
          'MarkerFaceColor', S.dock, 'MarkerEdgeColor','none');
lg = legend(ax, [h1 h2 h3 h4 h5 h6], ...
                {'LM (numerical)','MS (numerical)','LM (analytical)','MS (analytical)', ...
                 '\DeltaV_1','rendezvous'}, 'TextColor', S.text, 'Color', S.panel, ...
                 'EdgeColor', S.dim, 'Location','southoutside','Orientation','horizontal', ...
                 'FontSize', S.fsSmall);
lg.NumColumns = 3;
xlim(ax, 2400*[-1 1]); ylim(ax, 2400*[-1 1]);

ax2 = axes('Parent', fig, 'Position', [0.74 0.58 0.23 0.33]);
style_axes(ax2, 'radius', 't [h]', 'r [km]');
plot(ax2, t_all/3600, sqrt(sum(rLM.^2,1)), '-', 'Color', S.LM, 'LineWidth', 1.8);
plot(ax2, t_all/3600, sqrt(sum(rMS.^2,1)), '-', 'Color', S.MS, 'LineWidth', 1.4);
xlim(ax2, [0 t_end/3600]);

ax3 = axes('Parent', fig, 'Position', [0.74 0.12 0.23 0.33]);
style_axes(ax3, 'LM speed', 't [h]', '|v| [km/s]');
plot(ax3, t_all/3600, vn, '-', 'Color', S.transfer, 'LineWidth', 1.8);
xlim(ax3, [0 t_end/3600]);
M.fig03 = save_fig(fig, 'fig03_numerical_vs_analytical', C);

% --- fig04 : position errors ----------------------------------------------
fig = new_figure(1600, 800);
ax = axes('Parent', fig, 'Position', [0.09 0.13 0.87 0.76]);
style_axes(ax, 'Numerical minus analytical position (RelTol = AbsTol = 10^{-12})', ...
           't [h]', 'error [m]');
% STYLE_AXES leaves hold on, and semilogy on a held axes does not switch the
% scale. Set it explicitly or the plot silently comes out linear.
set(ax, 'YScale', 'log');
flo = 1e-9;                       % the error starts at exactly zero
e1 = semilogy(ax, t_all/3600, max(errLM, flo), '-', 'Color', S.LM, 'LineWidth', 1.6);
e2 = semilogy(ax, t_all/3600, max(errMS, flo), '-', 'Color', S.MS, 'LineWidth', 1.6);
e3 = semilogy(ax, t_all/3600, max(errRel,flo), '-', 'Color', S.transfer, 'LineWidth', 1.6);
ylim(ax, [flo 1e-2]);
plot(ax, [t_burn1 t_burn1]/3600, [flo 1e-2], '--', 'Color', S.dim);
plot(ax, [t_arr t_arr]/3600, [flo 1e-2], '--', 'Color', S.dim);
yline(ax, 1e-3, ':', 'acceptance: 1 mm', 'Color', S.warn, ...
      'LabelHorizontalAlignment', 'right', 'LabelVerticalAlignment', 'bottom', ...
      'FontSize', S.fsSmall, 'LineWidth', 1.5);
legend(ax, [e1 e2 e3], {'LM','MS','relative vector'}, 'TextColor', S.text, ...
       'Color', S.panel, 'EdgeColor', S.dim, 'Location','northwest', 'FontSize', S.fsSmall);
xlim(ax, [0 t_end/3600]);
M.fig04 = save_fig(fig, 'fig04_position_errors', C);

% --- fig05 : constants of motion ------------------------------------------
fig = new_figure(1600, 1000);
names = {'eccentricity  e', 'angular momentum  |h| [km^2/s]', 'specific energy  \epsilon [km^2/s^2]'};
data  = {eMag, hMag, epsSpec};
refs  = {[0 H.e 0], [H.h_in H.h_tr H.h_out], [H.eps_in H.eps_tr H.eps_out]};
for k = 1:3
    ax = subplot(3, 1, k, 'Parent', fig);
    style_axes(ax, names{k}, '', '');
    plot(ax, t_all/3600, data{k}, '-', 'Color', S.transfer, 'LineWidth', 2.0);
    for j = 1:3
        seg = {iA, iB, iC};
        plot(ax, t_all(seg{j}([1 end]))/3600, refs{k}(j)*[1 1], '--', ...
             'Color', S.dock, 'LineWidth', 1.0);
    end
    if k == 3, xlabel(ax, 't [h]', 'Color', S.dim); end
    xlim(ax, [0 t_end/3600]);
end
annotation(fig, 'textbox', [0.02 0.955 0.96 0.04], 'String', ...
    'Constants of motion: piecewise constant, analytical plateaus dashed', ...
    'Color', S.text, 'EdgeColor','none','FontSize', S.fsTitle, ...
    'FontName', S.font, 'HorizontalAlignment','center');
M.fig05 = save_fig(fig, 'fig05_constants_of_motion', C);

% ================================================================ OUTPUTS ==
events = struct('t_wait', t_burn1, 't_burn1', t_burn1, 't_arr', t_arr, ...
                't_end', t_end, 'theta_p', theta_p, ...
                'dV1_vec', dV1_vec, 'dV2_vec', dV2_vec, ...
                'iBurn1', iB(1), 'iArr', iArr);
traj = struct('t', t_all, 'rLM', rLM, 'vLM', vLM, 'rMS', rMS, 'vMS', vMS, ...
              'rLM_an', rLM_an, 'rMS_an', rMS_an, 'events', events, ...
              'H', H, 'P', P, 'ecc', eMag, 'hmag', hMag, 'eps', epsSpec); %#ok<NASGU>
save(fullfile(C.resDir, 'traj_part1.mat'), '-struct', 'traj');

M.H = H;  M.P = P;
M.dV1_ms   = H.dV1_ms;
M.dV2_ms   = H.dV2_ms;
M.dVtot_ms = H.dVtot_ms;
M.a_km = H.a; M.e = H.e;
M.dt_tof_s = H.dt_tof;
M.t_wait_s = P.t_wait;
M.t_wait_h = P.t_wait_h;
M.t_mission_h = P.t_mission_h;
M.dtheta_H_deg = P.dtheta_H_deg;
% NAMED integrator residual. Distinct from part 3's miss_LM_MS_twobody, which
% is a vehicle-to-vehicle separation rather than a numerical-versus-analytical
% difference. Quoting one for the other is the error this naming prevents.
M.miss_num_vs_kepler = max(errLM);
M.errLM_max_m = max(errLM);
M.errMS_max_m = max(errMS);
M.errRel_max_m = max(errRel);
M.miss_num_m = missNum;
M.eps_legs = [mean(epsSpec(iA)) mean(epsSpec(iB)) mean(epsSpec(iC))];
M.h_legs   = [mean(hMag(iA))   mean(hMag(iB))   mean(hMag(iC))];
M.e_legs   = [mean(eMag(iA))   mean(eMag(iB))   mean(eMag(iC))];

fprintf('Part 1 complete: 5 figures written.\n');
end
