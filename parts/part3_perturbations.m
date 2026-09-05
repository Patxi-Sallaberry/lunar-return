function M = part3_perturbations(C)
%PART3_PERTURBATIONS  Cowell propagation with lunar J2 and Earth third body.
%
%   The Part 1 rendezvous is designed in a pure two-body field. Here the same
%   manoeuvre plan is flown against a perturbed model and NOT retargeted: the
%   point is to measure what a Keplerian design actually misses by, which is
%   the number that sizes the mid-course correction budget.
%
%   Produces fig11..fig13 and results/traj_part3.mat.

fprintf('\n===== PART 3 | PERTURBED DYNAMICS (COWELL) ==============\n');
S = style();

H = hohmann_design(C.R1, C.R2, C.muMoon);
P = phasing_wait(C.n1, C.n2, H.dt_tof, C.phi0);
t_burn = P.t_wait;
t_end  = P.t_wait + H.dt_tof;

x0_LM = [C.R1; 0; 0; 0; H.vc1; 0];
x0_MS = [C.R2*cos(C.phi0); C.R2*sin(C.phi0); 0; ...
         -C.n2*C.R2*sin(C.phi0); C.n2*C.R2*cos(C.phi0); 0];

tA = linspace(0, t_burn, 3000);
tB = linspace(t_burn, t_end, 1500);
t_all = [tA, tB(2:end)];

models = struct( ...
    'name', {'Keplerian', 'J2', 'J2 + Earth 3B'}, ...
    'tag',  {'kep', 'J2', '3b'}, ...
    'f',    {@(t,x) fr2b(t, x, C.muMoon), ...
             @(t,x) fr2b_J2(t, x, C.muMoon, C.J2Moon, C.RMoon), ...
             @(t,x) fr2b_J2_3body(t, x, C)});

R_LM = cell(1,3);
R_MS = cell(1,3);
for k = 1:3
    R_LM{k} = fly_lm(models(k).f, x0_LM, tA, tB, H.dV1, C.odeWork);
    [~, XM] = ode45(models(k).f, t_all, x0_MS, C.odeWork);
    R_MS{k} = XM(:,1:3).';
end

d_kep    = R_LM{1}(:,end) - R_MS{1}(:,end);
d_J2     = R_LM{2}(:,end) - R_MS{2}(:,end);
d_J2_3B  = R_LM{3}(:,end) - R_MS{3}(:,end);
d_3Bonly = d_J2_3B - d_J2;

fprintf('Rendezvous miss at t = %.1f s, no retargeting:\n', t_end);
fprintf('  Keplerian reference     %10.4f m   (numerical noise floor)\n', norm(d_kep)*1e3);
fprintf('  J2 only                 %10.4f km\n', norm(d_J2));
fprintf('  J2 + Earth third body   %10.4f km\n', norm(d_J2_3B));
fprintf('  third-body contribution %10.2f m\n', norm(d_3Bonly)*1e3);

if norm(d_J2) < 1 || norm(d_J2) > 100
    fprintf('  [warn] J2 miss outside the expected 1-100 km band - check units.\n');
end

% ------------------------------------------------- mid-course correction ---
% The naive figure, kept only so the report can say why it is the wrong
% question: this is the Clohessy-Wiltshire cost of cancelling the offset over
% a fraction of an orbit, i.e. treating a phase error as a proximity manoeuvre.
dV_mcc_naive = C.n2 * norm(d_J2) * 1e3;

% The real thing: single shooting on a correcting impulse inside the same
% Cowell model, targeting the perturbed mothership at the nominal arrival.
mcOpt = struct('maxEval', 80, 'dV2_nom', H.dV2*1e3, 'ode', C.odeWork);
MC  = midcourse_correction(C, models(2).f, x0_LM, x0_MS, t_burn, H.dt_tof, H.dV1, mcOpt);
mcOptT = mcOpt; mcOptT.t_corr = t_burn + 0.5*H.dt_tof;
MCt = midcourse_correction(C, models(2).f, x0_LM, x0_MS, t_burn, H.dt_tof, H.dV1, mcOptT);

fprintf('\nMid-course correction, J2 model, single shooting in the same dynamics\n');
fprintf('  %-26s %8s %9s %9s %10s\n', 'impulse epoch', 'lever h', 'dV_mid', 'dV total', 'residual');
fprintf('  %-26s %8.2f %9.4f %9.4f %8.3f m\n', 'mid-mission (adopted)', ...
        MC.lever_s/3600, MC.dV_mid, MC.dV_extra, MC.miss_after*1e3);
fprintf('  %-26s %8.2f %9.4f %9.4f %8.3f m\n', 'mid-transfer', ...
        MCt.lever_s/3600, MCt.dV_mid, MCt.dV_extra, MCt.miss_after*1e3);
fprintf('  naive CW cancellation quoted for comparison: %.2f m/s\n', dV_mcc_naive);
fprintf('  the cost scales with the inverse lever arm, which is why the burn\n');
fprintf('  belongs in the phasing coast where the error is accumulated.\n');
dV_mcc = MC.dV_extra;

% ------------------------------------------- J2 secular rates, Vallado ------
% Closed-form mean-longitude rate against the numerically observed one. This
% replaces the old "a stiffer central field shifts n by dn/n = (1/2) dmu/mu"
% argument, which captures only the radial stiffening and is a factor of four
% low: the observable also carries the periapsis and node rates.
SR = struct('a', {C.R1, C.R2}, 'closed', {0,0}, 'numeric', {0,0}, 'rel', {0,0});
fprintf('\nJ2 secular mean-longitude rate, closed form (Vallado) vs Cowell\n');
for k = 1:2
    aK = SR(k).a;
    S2 = j2_secular_rates(C, aK, 0, 0);
    x0k = [aK; 0; 0; 0; sqrt(C.muMoon/aK); 0];
    [tk, Xk] = ode45(models(2).f, [0 6*2*pi/S2.n_bar], x0k, C.odeTight);
    pf = polyfit(tk, unwrap(atan2(Xk(:,2), Xk(:,1))), 1);
    SR(k).closed  = S2.lambdadot;
    SR(k).numeric = pf(1);
    SR(k).rel     = abs(pf(1) - S2.lambdadot) / S2.lambdadot;
    fprintf('  a = %7.1f km : closed %.9e  numeric %.9e  rel %.2e  excess %.3e\n', ...
            aK, S2.lambdadot, pf(1), SR(k).rel, S2.excess);
end

% --------------------------------------------- finite-burn gravity loss ----
GL = gravity_loss(C, H.dV1_ms, [0.1 0.3 1.0]);
fprintf('\nFinite-burn penalty on the %.2f m/s departure impulse (analytic)\n', H.dV1_ms);
fprintf('  %6s %12s %10s %10s %12s\n', 'T/W', 'a_thrust', 't_burn', 'arc', 'loss');
for k = 1:numel(GL)
    fprintf('  %6.1f %9.3f m/s2 %8.1f s %8.2f deg %9.4f m/s\n', ...
            GL(k).TW, GL(k).a_thrust, GL(k).tb, GL(k).arc_deg, GL(k).loss_ms);
end

% ------------------------------------------------ acceleration magnitudes --
a_kep = C.muMoon / C.R1^2 * 1e3;                                    % m/s^2
a_J2  = 1.5 * C.J2Moon * C.muMoon * C.RMoon^2 / C.R1^4 * 1e3;
a_3B  = 2 * C.muEarth * C.R1 / C.dEM^3 * 1e3;
fprintf('\n  Acceleration budget at r = R1 = %.1f km\n', C.R1);
fprintf('  ------------------------------------------------------\n');
fprintf('  central     %10.3e m/s^2    1\n', a_kep);
fprintf('  J2          %10.3e m/s^2    %.2e\n', a_J2, a_J2/a_kep);
fprintf('  Earth 3B    %10.3e m/s^2    %.2e\n', a_3B, a_3B/a_kep);
fprintf('  SRP (est.)  %10.3e m/s^2    %.2e   [not integrated, see docs]\n', ...
        1e-7, 1e-7/a_kep);

% ---------------------------------------------------------- COE histories --
kSub = round(linspace(1, numel(t_all), 700));
coeLM = coe_history(R_LM{3}, models(3).f, t_all, kSub, C, tA, tB, H.dV1, x0_LM);
coeMS = coe_history_simple(models(3).f, x0_MS, t_all, kSub, C);

% ================================================================ FIGURES ==
for k = 2:3
    fig = new_figure(1700, 900);
    ax = axes('Parent', fig, 'Position', [0.07 0.10 0.55 0.80]);
    if k == 2
        col = S.J2; ttl = 'Lunar J2 vs Keplerian design'; nm = 'fig11_j2_vs_kepler';
        dd = d_J2;
    else
        col = S.third; ttl = 'Lunar J2 + Earth third body vs Keplerian design';
        nm = 'fig12_j2_3body_vs_kepler'; dd = d_J2_3B;
    end
    style_axes(ax, ttl, 'x [km]', 'y [km]');
    axis(ax, 'equal');
    draw_moon(ax, C.RMoon);
    g1 = plot(ax, R_LM{1}(1,:), R_LM{1}(2,:), '-', 'Color', S.LM, 'LineWidth', 2.0);
    g2 = plot(ax, R_MS{1}(1,:), R_MS{1}(2,:), '-', 'Color', S.MS, 'LineWidth', 1.5);
    g3 = plot(ax, R_LM{k}(1,:), R_LM{k}(2,:), '--', 'Color', col, 'LineWidth', 2.0);
    plot(ax, R_LM{1}(1,end), R_LM{1}(2,end), 'o', 'MarkerSize', 10, ...
         'MarkerFaceColor', S.LM, 'MarkerEdgeColor','none');
    plot(ax, R_LM{k}(1,end), R_LM{k}(2,end), 'o', 'MarkerSize', 10, ...
         'MarkerFaceColor', col, 'MarkerEdgeColor','none');
    legend(ax, [g1 g2 g3], {'LM Keplerian','MS Keplerian','LM perturbed'}, ...
           'TextColor', S.text, 'Color', S.panel, 'EdgeColor', S.dim, ...
           'Location','southoutside','Orientation','horizontal','FontSize', S.fsSmall);
    xlim(ax, 2400*[-1 1]); ylim(ax, 2400*[-1 1]);

    % Zoom on the arrival neighbourhood, where the miss actually lives.
    ax2 = axes('Parent', fig, 'Position', [0.68 0.32 0.29 0.45]);
    style_axes(ax2, sprintf('arrival zoom  |  miss = %.2f km', norm(dd)), ...
               '\Deltax [km]', '\Deltay [km]');
    c0 = R_MS{k}(:,end);
    plot(ax2, R_LM{k}(1,end-400:end)-c0(1), R_LM{k}(2,end-400:end)-c0(2), '--', ...
         'Color', col, 'LineWidth', 2.0);
    plot(ax2, R_LM{1}(1,end-400:end)-c0(1), R_LM{1}(2,end-400:end)-c0(2), '-', ...
         'Color', S.LM, 'LineWidth', 1.6);
    plot(ax2, 0, 0, 's', 'MarkerSize', 12, 'MarkerFaceColor', S.MS, 'MarkerEdgeColor','none');
    quiver(ax2, 0, 0, dd(1), dd(2), 0, 'Color', S.warn, 'LineWidth', 2.0, 'MaxHeadSize', 0.6);
    axis(ax2, 'equal');
    if k == 2
        M.fig11 = save_fig(fig, nm, C);
    else
        M.fig12 = save_fig(fig, nm, C);
    end
end

% --- fig13 : classical orbital elements -----------------------------------
fig = new_figure(1700, 1000);
flds = {'a','e','i','RAAN','argp','nu'};
unis = {'a [km]','e [-]','i [deg]','\Omega [deg]','\omega [deg]','\nu [deg]'};
for k = 1:6
    ax = subplot(2,3,k,'Parent',fig);
    style_axes(ax, unis{k}, 't [h]', '');
    plot(ax, t_all(kSub)/3600, [coeLM.(flds{k})], '-',  'Color', S.LM, 'LineWidth', 1.8);
    plot(ax, t_all(kSub)/3600, [coeMS.(flds{k})], '--', 'Color', S.MS, 'LineWidth', 1.6);
    xlim(ax, [0 t_end/3600]);
end
annotation(fig,'textbox',[0.02 0.955 0.96 0.04],'String', ...
    'Classical elements under J2 + Earth third body   |   LM solid, MS dashed', ...
    'Color', S.text,'EdgeColor','none','FontSize', S.fsAxis,'FontName',S.font, ...
    'HorizontalAlignment','center');
M.fig13 = save_fig(fig, 'fig13_coe_histories', C);

% ================================================================ OUTPUTS ==
traj = struct('t', t_all, ...
              'rLM_kep', R_LM{1}, 'rLM_J2', R_LM{2}, 'rLM_3b', R_LM{3}, ...
              'rMS_kep', R_MS{1}, 'rMS_J2', R_MS{2}, 'rMS_3b', R_MS{3}, ...
              'd_kep', d_kep, 'd_J2', d_J2, 'd_J2_3B', d_J2_3B, ...
              'd_3Bonly', d_3Bonly, 't_burn', t_burn); %#ok<NASGU>
save(fullfile(C.resDir, 'traj_part3.mat'), '-struct', 'traj');

% NAMED two-body miss. This is the LM-MS separation at nominal arrival through
% the Cowell pipeline with perturbations switched off - a different quantity
% from Part 1's max |r_ode - r_kepler|, which is an integrator residual. The
% report used to quote both under one name; they are now distinct fields and
% Table 5 uses this one only.
M.miss_LM_MS_twobody = norm(d_kep) * 1e3;
M.miss_kep_m   = norm(d_kep) * 1e3;          % retained: older name, same value
M.miss_J2_km   = norm(d_J2);
M.miss_J2_3B_km = norm(d_J2_3B);
M.miss_3Bonly_m = norm(d_3Bonly) * 1e3;

M.dV_mcc_ms       = dV_mcc;                  % the real retarget, mid-mission
M.dV_mcc_naive_ms = dV_mcc_naive;            % the CW figure, kept for contrast
M.mcc_dV_mid      = MC.dV_mid;
M.mcc_resid_m     = MC.miss_after * 1e3;
M.mcc_lever_h     = MC.lever_s / 3600;
M.mcc_midtransfer = MCt.dV_extra;
M.j2_rate_rel_R1  = SR(1).rel;
M.j2_rate_rel_R2  = SR(2).rel;
M.j2_excess_R1    = SR(1).closed / sqrt(C.muMoon/C.R1^3) - 1;
M.gloss_TW01      = GL(1).loss_ms;
M.gloss_TW03      = GL(2).loss_ms;
M.gloss_TW10      = GL(3).loss_ms;
M.gloss_tb01      = GL(1).tb;
M.a_kep = a_kep; M.a_J2 = a_J2; M.a_3B = a_3B;

fprintf('Part 3 complete: 3 figures written.\n');
end

% ------------------------------------------------------------------ helpers --
function R = fly_lm(f, x0, tA, tB, dV1, opts)
%FLY_LM  Coast, burn tangentially along the PERTURBED velocity, then transfer.
[~, XA] = ode45(f, tA, x0, opts);
xb = XA(end,:).';
xb(4:6) = xb(4:6) + dV1 * xb(4:6)/norm(xb(4:6));
[~, XB] = ode45(f, tB, xb, opts);
R = [XA(:,1:3); XB(2:end,1:3)].';
end

function S = coe_history(~, f, tAll, kSub, C, tA, tB, dV1, x0)
%COE_HISTORY  Elements of the LM, re-propagated so velocities are available.
[~, XA] = ode45(f, tA, x0, C.odeWork);
xb = XA(end,:).';
xb(4:6) = xb(4:6) + dV1 * xb(4:6)/norm(xb(4:6));
[~, XB] = ode45(f, tB, xb, C.odeWork);
X = [XA; XB(2:end,:)];
S = pack_coe(X(kSub,:), C);
end

function S = coe_history_simple(f, x0, tAll, kSub, C)
[~, X] = ode45(f, tAll, x0, C.odeWork);
S = pack_coe(X(kSub,:), C);
end

function S = pack_coe(X, C)
N = size(X,1);
S = struct('a',zeros(1,N),'e',zeros(1,N),'i',zeros(1,N), ...
           'RAAN',zeros(1,N),'argp',zeros(1,N),'nu',zeros(1,N));
for k = 1:N
    c = rv2coe(X(k,1:3), X(k,4:6), C.muMoon);
    S.a(k)=c.a; S.e(k)=c.e; S.i(k)=c.i;
    S.RAAN(k)=c.RAAN; S.argp(k)=c.argp; S.nu(k)=c.nu;
end
end
