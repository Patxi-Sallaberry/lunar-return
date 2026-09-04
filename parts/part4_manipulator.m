function M = part4_manipulator(C)
%PART4_MANIPULATOR  5R berthing arm: mobility, kinematics and kineto-statics.
%
%   Once the lunar module is at the docking port a robotic arm has to capture
%   and berth it. This part sizes the static problem: given a contact wrench
%   at the grapple fixture, what torque does each joint see and what reaction
%   does the mothership attitude control system have to absorb?
%
%   Produces fig14, fig15 and results/traj_part4.mat.

fprintf('\n===== PART 4 | 5R BERTHING MANIPULATOR ==================\n');
S = style();
P = manipulator_params(C);

% ------------------------------------------------------------- mobility ----
mDim = 6; Nb = P.n + 1; Jn = P.n;
dofJoints = mDim*(Nb - 1 - Jn) + Jn;
dofTotal  = dofJoints + 6;
fprintf('Grubler:  m=%d, N=%d bodies, J=%d joints  ->  DOF_joints = %d, DOF_total = %d\n', ...
        mDim, Nb, Jn, dofJoints, dofTotal);
fprintf('Free-flying base assumed held by the AOCS, so only the %d joint DOF are actuated here.\n', Jn);

% ------------------------------------------------------ inertia inventory --
fprintf('\n  Link    m [kg]   L [m]   Ixx=Iyy [kg m^2]   Izz [kg m^2]\n');
fprintf('  --------------------------------------------------------\n');
for i = 1:P.n
    fprintf('  %2d   %8.1f  %6.2f   %14.4f   %12.4f\n', i, P.m(i), P.L(i), P.Ixx(i), P.Izz(i));
end
fprintf('  total mass %.1f kg, fully extended reach %.2f m\n', P.mTotal, P.reach);

% ------------------------------------------------- FK verification pose ----
q_ref = deg2rad([0 45 0 60 0]).';
FKr = fkine_5R(q_ref, P);
fprintf('\nFK acceptance pose theta = [0 45 0 60 0] deg  (p_mount = [%g %g %g])\n', P.p_mount);
disp(round(FKr.T_EE, 4));
R_expected = rot_axis_angle([0;1;0], deg2rad(105));
fprintf('  rotation matches Ry(105 deg) to %.2e\n', norm(FKr.R_EE - R_expected));
fprintf('  end-effector at [%.4f %.4f %.4f] m, |p| = %.3f m\n', FKr.p_EE, norm(FKr.p_EE));

% ------------------------------------------- postures x contact scenarios ---
postures = {C.q_ext, C.q_bent, C.q_arb};
pnames   = {'nearly extended', 'folded', 'general spatial'};
wrenches = {C.wrench1, C.wrench2};
wnames   = {'axial   F=[0 0 -100] N, M=0', 'misaligned F=[15 -10 -80] N, M=[12 8 -5] Nm'};

M.tau_m   = zeros(P.n, 3, 2);
M.tau_0   = zeros(6, 3, 2);
M.forceResidual = zeros(3, 2);
M.dualityResidual = zeros(3, 2);

for w = 1:2
    fprintf('\n  Scenario %d : %s\n', w, wnames{w});
    fprintf('  posture            tau1     tau2     tau3     tau4     tau5   | |f_base| |n_base|\n');
    fprintf('  ------------------------------------------------------------------------------\n');
    for p = 1:3
        FK = fkine_5R(postures{p}, P);
        N  = system_jacobian_N(FK, P);
        W  = contact_wrench(FK, P, wrenches{w}.F, wrenches{w}.M);

        tau = N.' * W.w;
        tau0 = tau(1:6);
        taum = tau(7:end);

        % Independent check: the joint torques must equal J_geom' * [f; n]
        % with the wrench taken directly at the tip.
        Jg = geometric_jacobian(FK);
        taum_alt = Jg.' * [W.F_I; W.M_I];

        M.tau_m(:,p,w) = taum;
        M.tau_0(:,p,w) = tau0;
        M.forceResidual(p,w)   = abs(norm(tau0(4:6)) - norm(W.F_I));
        M.dualityResidual(p,w) = norm(taum - taum_alt);

        fprintf('  %-16s %8.2f %8.2f %8.2f %8.2f %8.2f | %8.2f %8.2f\n', ...
                pnames{p}, taum, norm(tau0(4:6)), norm(tau0(1:3)));
    end
    fprintf('  force-equilibrium residual max %.2e N, duality residual max %.2e N m\n', ...
            max(M.forceResidual(:,w)), max(M.dualityResidual(:,w)));
end

fprintf('\n  Reading of the tables:\n');
fprintf('  - nearly extended, pure axial push: the load runs along the links, so the\n');
fprintf('    y-axis joints see a small moment arm and tau2..tau4 stay modest.\n');
fprintf('  - folded: the same force acts on a long transverse arm, and the shoulder\n');
fprintf('    (joint 2) takes the largest torque of the whole study.\n');
fprintf('  - the misaligned wrench is the one that lights up the wrist roll (joint 5)\n');
fprintf('    and the base turret (joint 1), which the axial case leaves at zero.\n');
fprintf('  - the base reaction -tau0 is what the mothership AOCS must reject; its force\n');
fprintf('    part equals |F| exactly, as a static chain with one external force demands.\n');
fprintf('  - masses do not appear anywhere above: in micro-gravity the static problem is\n');
fprintf('    mass-free. They would enter H and C in the free-floating dynamics.\n');

% ================================================================ FIGURES ==
% --- fig14 : FK verification ----------------------------------------------
fig = new_figure(1700, 900);
ax = axes('Parent', fig, 'Position', [0.04 0.08 0.52 0.82]);
style_axes(ax, 'Forward kinematics, \theta = [0, 45, 0, 60, 0]\circ', ...
           'x [m]', 'y [m]', 'z [m]');
axis(ax, 'equal'); view(ax, 40, 18);
draw_arm(ax, FKr, P);
camlight(ax, 'headlight'); lighting(ax, 'gouraud');
text(ax, FKr.p_EE(1), FKr.p_EE(2), FKr.p_EE(3), ...
     sprintf('  EE = [%.3f, %.3f, %.3f] m', FKr.p_EE), ...
     'Color', S.transfer, 'FontSize', S.fsSmall);
xlim(ax, [-2 8]); ylim(ax, [-3 3]); zlim(ax, [-2 8]);

ax2 = axes('Parent', fig, 'Position', [0.62 0.08 0.35 0.82]);
style_axes(ax2, 'XZ projection', 'x [m]', 'z [m]');
axis(ax2, 'equal');
pts = [FKr.r_j, FKr.p_EE];
plot(ax2, pts(1,:), pts(3,:), '-o', 'Color', S.LM, 'LineWidth', 3.0, ...
     'MarkerFaceColor', S.hold, 'MarkerEdgeColor','none', 'MarkerSize', 9);
plot(ax2, FKr.p_EE(1), FKr.p_EE(3), 'p', 'MarkerSize', 17, ...
     'MarkerFaceColor', S.transfer, 'MarkerEdgeColor','none');
for i = 1:P.n
    text(ax2, FKr.r_j(1,i), FKr.r_j(3,i), sprintf('  J%d', i), ...
         'Color', S.dim, 'FontSize', S.fsSmall);
end
xlim(ax2, [-1 7]); ylim(ax2, [-1 7]);
annotation(fig,'textbox',[0.02 0.93 0.96 0.05],'String', ...
    sprintf('5R berthing arm  |  links [%.1f %.1f %.1f %.1f %.1f] m, reach %.1f m, total mass %.0f kg', ...
            P.L, P.reach, P.mTotal), ...
    'Color', S.text,'EdgeColor','none','FontSize', S.fsAxis,'FontName',S.font, ...
    'HorizontalAlignment','center');
M.fig14 = save_fig(fig, 'fig14_fkine_verification', C);

% --- fig15 : three postures -----------------------------------------------
fig = new_figure(1800, 660);
for p = 1:3
    ax = axes('Parent', fig, 'Position', [0.025 + 0.327*(p-1), 0.055, 0.30, 0.79]);
    FK = fkine_5R(postures{p}, P);
    style_axes(ax, sprintf('%s\n\\tau_2 = %.1f N m (axial case)', pnames{p}, M.tau_m(2,p,1)), ...
               'x [m]', 'y [m]', 'z [m]');
    axis(ax, 'equal'); view(ax, 40, 18);
    draw_arm(ax, FK, P);
    camlight(ax, 'headlight'); lighting(ax, 'gouraud');
    Wv = contact_wrench(FK, P, wrenches{1}.F, wrenches{1}.M);
    fq = Wv.F_I / norm(Wv.F_I) * 2.4;
    quiver3(ax, FK.p_EE(1), FK.p_EE(2), FK.p_EE(3), fq(1), fq(2), fq(3), 0, ...
            'Color', S.warn, 'LineWidth', 3.2, 'MaxHeadSize', 0.9);
    xlim(ax, [-2 8]); ylim(ax, [-4 4]); zlim(ax, [-2 8]);
end
annotation(fig,'textbox',[0.02 0.93 0.96 0.05],'String', ...
    'Three postures under the 100 N axial berthing load (orange arrow)', ...
    'Color', S.text,'EdgeColor','none','FontSize', S.fsAxis,'FontName',S.font, ...
    'HorizontalAlignment','center');
M.fig15 = save_fig(fig, 'fig15_three_postures', C);

% ================================================================ OUTPUTS ==
% Demo joint path: a smooth sweep through the three study postures, used by
% the animation so it never has to redo any kinematics reasoning.
tDemo = linspace(0, 1, 240);
qDemo = zeros(P.n, numel(tDemo));
key = [C.q_ext, C.q_bent, C.q_arb, C.q_ext];
for k = 1:numel(tDemo)
    s = tDemo(k) * 3;
    i = min(floor(s) + 1, 3);
    u = s - (i-1);
    u = 3*u^2 - 2*u^3;                    % smoothstep between key postures
    qDemo(:,k) = (1-u)*key(:,i) + u*key(:,i+1);
end

traj = struct('q_ref', q_ref, 'T_EE_ref', FKr.T_EE, ...
              'postures', [C.q_ext, C.q_bent, C.q_arb], ...
              'posture_names', {pnames}, ...
              't_demo', tDemo, 'q_demo', qDemo, ...
              'tau_m', M.tau_m, 'tau_0', M.tau_0); %#ok<NASGU>
save(fullfile(C.resDir, 'traj_part4.mat'), '-struct', 'traj');

M.dofTotal = dofTotal;
M.reach_m  = P.reach;
M.mass_kg  = P.mTotal;
M.p_EE_ref = FKr.p_EE;
M.R_err_ref = norm(FKr.R_EE - R_expected);
M.tau_max_Nm = max(abs(M.tau_m(:)));
M.forceResidual_max = max(M.forceResidual(:));
M.dualityResidual_max = max(M.dualityResidual(:));

fprintf('Part 4 complete: 2 figures written.\n');
end
