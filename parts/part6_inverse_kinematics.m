function M = part6_inverse_kinematics(C)
%PART6_INVERSE_KINEMATICS  WDLS inverse kinematics and a rest-to-rest capture.
%
%   The arm has five joints and the task has six degrees of freedom, so the
%   pose problem is structurally unsolvable in general. The weighted damped
%   least-squares solver handles that honestly: it buys position accuracy with
%   attitude residual by de-weighting the component the wrist cannot serve.
%
%   Two targets are run. The first is the forward-kinematics pose of a known
%   configuration, so an exact solution provably exists and the convergence
%   claim is meaningful. The second is an operationally motivated pose in
%   front of the docking face, where the attitude residual is expected to
%   survive.
%
%   Produces fig17, fig20 and results/traj_part6.mat.

fprintf('\n===== PART 6 | INVERSE KINEMATICS + TRAJECTORY ==========\n');
S = style();
P = manipulator_params(C);

opts = struct('lambda', C.ik_lambda, 'alpha', C.ik_alpha, 'W', C.ik_W, ...
              'maxIter', C.ik_maxIter, 'tolPos', C.ik_tolPos);

% ------------------------------------------------------------- target 1 ----
FKt = fkine_5R(C.q_arb, P);
p_t1 = FKt.p_EE;
R_t1 = FKt.R_EE;

% Seed cascade. The all-zero pose is a genuine singularity for this chain:
% fully extended along z, joint 1 produces no end-effector translation at all.
% Rather than pretend otherwise, try it first and fall back deterministically.
seeds = { zeros(5,1), ...
          deg2rad([ 5;  20; -10;  15;   5]), ...
          deg2rad([20;  40; -30;  20;  10]), ...
          deg2rad([-15; 55; -45;  30; -20]) };
seedNames = {'zero pose', 'slightly bent', 'mid-workspace', 'alternate branch'};

R1 = [];
for s = 1:numel(seeds)
    R1 = wdls_ik(seeds{s}, p_t1, R_t1, P, opts);
    if R1.converged
        fprintf('Target 1 (reachable pose of q_arb): converged from the %s seed\n', seedNames{s});
        break
    end
    fprintf('Target 1: %s seed stalled at %.3f mm after %d iterations, trying the next.\n', ...
            seedNames{s}, R1.err_pos_final*1e3, R1.iters);
end
usedSeed = min(s, numel(seeds));

fprintf('  iterations to 1 mm : %d (cap %d)\n', R1.iters, C.ik_maxIter);
fprintf('  position residual  : %.4f mm\n', R1.err_pos_final * 1e3);
fprintf('  attitude residual  : %.4e (Siciliano vector norm)\n', R1.err_ori_final);
fprintf('  q* = [%s] deg\n', strtrim(sprintf('%8.3f', rad2deg(R1.q))));

% ------------------------------------------------------------- target 2 ----
% 0.4 m in front of the mothership docking face (the +x face of the 2 m bus),
% approach axis along +x, i.e. the tool z axis rotated onto +x.
p_t2 = [P.busCenter(1) + P.busEdge/2 + 0.4; 0; 0.4];
R_t2 = rot_axis_angle([0;1;0], pi/2);
R2 = wdls_ik(deg2rad([0; 45; -60; 20; 0]), p_t2, R_t2, P, opts);
fprintf('Target 2 (docking-face approach pose, 5R cannot serve all 6 DOF):\n');
fprintf('  position residual  : %.4f mm after %d iterations\n', R2.err_pos_final*1e3, R2.iters);
fprintf('  attitude residual  : %.4e - retained by design, W de-weights it\n', R2.err_ori_final);

% ------------------------------------------------------ cubic joint path ----
q_start = zeros(5,1);                      % stowed configuration
tGrid = linspace(0, C.ik_tf, 601);
Tr = cubic_joint_traj(q_start, R1.q, C.ik_tf, tGrid);

fprintf('Rest-to-rest cubic, tf = %.0f s:\n', C.ik_tf);
fprintf('  |qdot(0)| = %.3e rad/s, |qdot(tf)| = %.3e rad/s\n', ...
        norm(Tr.qd(:,1)), norm(Tr.qd(:,end)));
fprintf('  peak joint rate %.4f rad/s on joint %d\n', ...
        max(abs(Tr.qd(:))), find(max(abs(Tr.qd),[],2) == max(abs(Tr.qd(:))), 1));

% End-effector path along the manoeuvre, stored for the animation.
pEE = zeros(3, numel(tGrid));
T_EE = zeros(4, 4, numel(tGrid));
for k = 1:numel(tGrid)
    FKk = fkine_5R(Tr.q(:,k), P);
    pEE(:,k) = FKk.p_EE;
    T_EE(:,:,k) = FKk.T_EE;
end
pathLen = sum(sqrt(sum(diff(pEE, 1, 2).^2, 1)));
fprintf('  end-effector travels %.3f m along the capture path\n', pathLen);

% ================================================================ FIGURES ==
% --- fig17 : joint trajectory ---------------------------------------------
fig = new_figure(1600, 1000);
cols = [S.LM; S.transfer; S.hold; S.MS; S.J2];
ax = axes('Parent', fig, 'Position', [0.09 0.57 0.87 0.34]);
style_axes(ax, 'Joint positions', '', '\theta [deg]');
for i = 1:P.n
    plot(ax, tGrid, rad2deg(Tr.q(i,:)), '-', 'Color', cols(i,:), 'LineWidth', 2.2);
end
legend(ax, arrayfun(@(i) sprintf('joint %d', i), 1:P.n, 'UniformOutput', false), ...
       'TextColor', S.text, 'Color', S.panel, 'EdgeColor', S.dim, ...
       'Location','northwest','Orientation','horizontal','FontSize', S.fsSmall);
xlim(ax, [0 C.ik_tf]);

ax2 = axes('Parent', fig, 'Position', [0.09 0.09 0.87 0.36]);
style_axes(ax2, 'Joint rates: zero at both ends by construction', 't [s]', '\theta'' [rad/s]');
for i = 1:P.n
    plot(ax2, tGrid, Tr.qd(i,:), '-', 'Color', cols(i,:), 'LineWidth', 2.2);
end
yline(ax2, 0, ':', 'Color', S.dim);
xlim(ax2, [0 C.ik_tf]);
annotation(fig,'textbox',[0.02 0.955 0.96 0.04],'String', ...
    sprintf('Rest-to-rest cubic joint trajectory, t_f = %.0f s, stowed pose to the WDLS solution', C.ik_tf), ...
    'Color', S.text,'EdgeColor','none','FontSize', S.fsAxis,'FontName',S.font, ...
    'HorizontalAlignment','center');
M.fig17 = save_fig(fig, 'fig17_joint_trajectory', C);

% --- fig20 : convergence + capture geometry -------------------------------
fig = new_figure(1700, 850);
ax = axes('Parent', fig, 'Position', [0.06 0.12 0.38 0.72]);
style_axes(ax, 'WDLS convergence', 'iteration', 'residual');
set(ax, 'YScale', 'log');        % semilogy on a held axes would not do it
semilogy(ax, 0:numel(R1.err_pos)-1, max(R1.err_pos, 1e-12), '-', ...
         'Color', S.transfer, 'LineWidth', 2.2);
semilogy(ax, 0:numel(R1.err_ori)-1, max(R1.err_ori, 1e-12), '-', ...
         'Color', S.hold, 'LineWidth', 1.8);
semilogy(ax, 0:numel(R2.err_pos)-1, max(R2.err_pos, 1e-12), '--', ...
         'Color', S.J2, 'LineWidth', 1.8);
yline(ax, C.ik_tolPos, ':', '1 mm', 'Color', S.warn, 'FontSize', S.fsSmall);
legend(ax, {'target 1 |\Deltap| [m]','target 1 |e_o|','target 2 |\Deltap| [m]'}, ...
       'TextColor', S.text, 'Color', S.panel, 'EdgeColor', S.dim, ...
       'Location','northeast','FontSize', S.fsSmall);

% Top kept clear of the figure-wide annotation: at report font sizes the panel
% title and the annotation were landing on the same line.
ax2 = axes('Parent', fig, 'Position', [0.50 0.07 0.47 0.78]);
style_axes(ax2, 'Capture path of the end effector', 'x [m]', 'y [m]', 'z [m]');
axis(ax2, 'equal'); view(ax2, 42, 20);
FK0 = fkine_5R(q_start, P);
draw_arm(ax2, FK0, P);
FKf = fkine_5R(R1.q, P);
ptsF = [FKf.r_j, FKf.p_EE];
plot3(ax2, ptsF(1,:), ptsF(2,:), ptsF(3,:), '-o', 'Color', S.transfer, ...
      'LineWidth', 2.4, 'MarkerFaceColor', S.transfer, 'MarkerEdgeColor','none', 'MarkerSize', 6);
plot3(ax2, pEE(1,:), pEE(2,:), pEE(3,:), '-', 'Color', S.hold, 'LineWidth', 2.2);
plot3(ax2, p_t1(1), p_t1(2), p_t1(3), 'p', 'MarkerSize', 18, ...
      'MarkerFaceColor', S.dock, 'MarkerEdgeColor','none');
camlight(ax2, 'headlight'); lighting(ax2, 'gouraud');
xlim(ax2, [-2 8]); ylim(ax2, [-4 4]); zlim(ax2, [-2 8]);
annotation(fig,'textbox',[0.02 0.93 0.96 0.05],'String', ...
    sprintf('Inverse kinematics: %.3f mm position residual, %d iterations, \\lambda = %.2f, \\alpha = %.1f', ...
            R1.err_pos_final*1e3, R1.iters, C.ik_lambda, C.ik_alpha), ...
    'Color', S.text,'EdgeColor','none','FontSize', S.fsAxis,'FontName',S.font, ...
    'HorizontalAlignment','center');
M.fig20 = save_fig(fig, 'fig20_ik_convergence', C);

% ================================================================ OUTPUTS ==
traj = struct('t', tGrid, 'q', Tr.q, 'qd', Tr.qd, 'qdd', Tr.qdd, ...
              'p_EE', pEE, 'T_EE', T_EE, ...
              'q_target', R1.q, 'p_target1', p_t1, 'R_target1', R_t1, ...
              'p_target2', p_t2, 'q_target2', R2.q, ...
              'err_pos1', R1.err_pos, 'err_ori1', R1.err_ori, ...
              'err_pos2', R2.err_pos); %#ok<NASGU>
save(fullfile(C.resDir, 'traj_part6.mat'), '-struct', 'traj');

M.ik_iters        = R1.iters;
M.ik_seed         = seedNames{usedSeed};
M.ik_res_mm       = R1.err_pos_final * 1e3;
M.ik_ori_res      = R1.err_ori_final;
M.ik2_res_mm      = R2.err_pos_final * 1e3;
M.ik2_ori_res     = R2.err_ori_final;
M.q_target_deg    = rad2deg(R1.q).';
M.traj_tf_s       = C.ik_tf;
M.qdot_peak       = max(abs(Tr.qd(:)));
M.ee_path_len_m   = pathLen;
M.converged       = R1.converged;

fprintf('Part 6 complete: 2 figures written.\n');
end
