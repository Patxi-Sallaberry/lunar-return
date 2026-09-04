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

% Mid-course correction scale: the miss has to be removed over roughly one
% orbit, so the equivalent impulse is of order n2 * |miss|.
dV_mcc = C.n2 * norm(d_J2) * 1e3;
fprintf('  equivalent mid-course correction ~ n2*|miss| = %.2f m/s\n', dV_mcc);

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

M.miss_kep_m   = norm(d_kep) * 1e3;
M.miss_J2_km   = norm(d_J2);
M.miss_J2_3B_km = norm(d_J2_3B);
M.miss_3Bonly_m = norm(d_3Bonly) * 1e3;
M.dV_mcc_ms    = dV_mcc;
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
