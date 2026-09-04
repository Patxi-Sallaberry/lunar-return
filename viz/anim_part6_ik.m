function R = anim_part6_ik(C)
%ANIM_PART6_IK  Supplementary clip 06b: inverse-kinematics telemetry.
%
%   Same capture as clip 06, shot as an engineering read-out instead of a
%   hero shot: joint positions, joint rates and the end-effector error
%   alongside the arm. Not part of the 90 s showreel; it is the clip to open
%   when someone asks "does the trajectory actually respect the rest-to-rest
%   boundary conditions?". Loads results/traj_part6.mat only.

D = load(fullfile(C.resDir, 'traj_part6.mat'));
S = style();
P = manipulator_params(C);

screen_s = 10;
nF = round(screen_s * C.videoFps);
ii = round(linspace(1, size(D.q, 2), nF));

fig = new_figure(C.videoRes(1), C.videoRes(2));
ax = axes('Parent', fig, 'Position', [0.030 0.205 0.420 0.665]);
style_axes(ax, '', 'x [m]', 'y [m]', 'z [m]');
axis(ax, 'equal'); view(ax, 44, 20);
FK0 = fkine_5R(D.q(:,1), P);
hArm = draw_arm(ax, FK0, P);
hTrail = plot3(ax, NaN, NaN, NaN, '-', 'Color', S.hold, 'LineWidth', 2.4);
plot3(ax, D.p_target1(1), D.p_target1(2), D.p_target1(3), 'p', 'MarkerSize', 20, ...
      'MarkerFaceColor', S.dock, 'MarkerEdgeColor', 'none');
xlim(ax, [-2.5 8]); ylim(ax, [-4.5 4.5]); zlim(ax, [-2.5 8]);
hl = camlight(ax, 'headlight'); lighting(ax, 'gouraud');

cols = [S.LM; S.transfer; S.hold; S.MS; S.J2];
ax2 = axes('Parent', fig, 'Position', [0.540 0.640 0.420 0.235]);
style_axes(ax2, 'joint positions', '', 'deg');
hQ = gobjects(1,P.n);
for i = 1:P.n
    plot(ax2, D.t, rad2deg(D.q(i,:)), '-', 'Color', [cols(i,:) 0.25], 'LineWidth', 1.2);
    hQ(i) = plot(ax2, NaN, NaN, '-', 'Color', cols(i,:), 'LineWidth', 2.4);
end
xlim(ax2, [0 D.t(end)]);

ax3 = axes('Parent', fig, 'Position', [0.540 0.360 0.420 0.215]);
style_axes(ax3, 'joint rates: zero at both ends', '', 'rad/s');
hV = gobjects(1,P.n);
for i = 1:P.n
    plot(ax3, D.t, D.qd(i,:), '-', 'Color', [cols(i,:) 0.25], 'LineWidth', 1.2);
    hV(i) = plot(ax3, NaN, NaN, '-', 'Color', cols(i,:), 'LineWidth', 2.4);
end
xlim(ax3, [0 D.t(end)]);

ax4 = axes('Parent', fig, 'Position', [0.540 0.195 0.420 0.110]);
style_axes(ax4, 'distance to the commanded pose', 't [s]', 'm');
hE = plot(ax4, NaN, NaN, '-', 'Color', S.warn, 'LineWidth', 2.4);
xlim(ax4, [0 D.t(end)]);
errAll = sqrt(sum((D.p_EE - D.p_target1).^2, 1));
ylim(ax4, [0 max(errAll)*1.1]);

hud = annotate_hud(fig, 6, 'Inverse kinematics  ·  WDLS solution and rest-to-rest cubic');

R = render_clip(fig, @frame, nF, '06b_ik_telemetry', C);

    function frame(k)
        i = ii(k);
        FK = fkine_5R(D.q(:,i), P);
        update_arm(hArm, FK);
        set(hTrail, 'XData', D.p_EE(1,1:i), 'YData', D.p_EE(2,1:i), 'ZData', D.p_EE(3,1:i));
        for q = 1:P.n
            set(hQ(q), 'XData', D.t(1:i), 'YData', rad2deg(D.q(q,1:i)));
            set(hV(q), 'XData', D.t(1:i), 'YData', D.qd(q,1:i));
        end
        set(hE, 'XData', D.t(1:i), 'YData', errAll(1:i));
        camlight(hl, 'headlight');

        flash = '';
        if k > nF - 16, flash = 'POSE ACQUIRED'; end
        hud_set(hud, {sprintf('%5.1f s', D.t(i)), sprintf('%.3f m', errAll(i)), ...
                      sprintf('%.4f rad/s', max(abs(D.qd(:,i)))), 'x 3'}, ...
                {'TRAJECTORY TIME', 'POSE ERROR', 'PEAK RATE', 'TIME RATE'}, flash);
    end
end
