function R = anim_part4_arm(C)
%ANIM_PART4_ARM  Clip 06: the 5R berthing arm, statics then capture.
%
%   Two beats. First a sweep through the three study postures with the joint
%   torques produced by a 100 N axial berthing load recomputed live, so the
%   viewer sees the shoulder load explode as the arm folds. Then the 30 s
%   rest-to-rest capture from Part 6, ending on CONTACT.
%
%   Loads results/traj_part4.mat and results/traj_part6.mat. Forward
%   kinematics and the kineto-static map are evaluated here because they are
%   pure functions of the stored joint angles - no trajectory is re-solved.

D4 = load(fullfile(C.resDir, 'traj_part4.mat'));
D6 = load(fullfile(C.resDir, 'traj_part6.mat'));
S = style();
P = manipulator_params(C);

nA = round(4  * C.videoFps);
nB = round(12 * C.videoFps);
nF = nA + nB;

iA = round(linspace(1, size(D4.q_demo, 2), nA));
iB = round(linspace(1, size(D6.q, 2), nB));

% ----------------------------------------------------------------- scene ---
fig = new_figure(C.videoRes(1), C.videoRes(2));
ax = axes('Parent', fig, 'Position', [0.030 0.205 0.470 0.665]);
style_axes(ax, '', 'x [m]', 'y [m]', 'z [m]');
axis(ax, 'equal'); view(ax, 40, 18);
FK0 = fkine_5R(D4.q_demo(:,1), P);
hArm = draw_arm(ax, FK0, P);
hTrail = plot3(ax, NaN, NaN, NaN, '-', 'Color', S.hold, 'LineWidth', 2.4);
hTgt = plot3(ax, D6.p_target1(1), D6.p_target1(2), D6.p_target1(3), 'p', ...
             'MarkerSize', 20, 'MarkerFaceColor', S.dock, 'MarkerEdgeColor', 'none', ...
             'Visible', 'off');
hForce = quiver3(ax, 0,0,0, 0,0,0, 0, 'Color', S.warn, 'LineWidth', 3.0, 'MaxHeadSize', 0.8);
xlim(ax, [-2.5 8]); ylim(ax, [-4.5 4.5]); zlim(ax, [-2.5 8]);
hl = camlight(ax, 'headlight'); lighting(ax, 'gouraud');

ax2 = axes('Parent', fig, 'Position', [0.600 0.545 0.360 0.330]);
style_axes(ax2, 'joint torque under a 100 N axial berthing load', 'joint', 'N m');
hBar = bar(ax2, 1:P.n, zeros(1,P.n), 0.6, 'FaceColor', S.transfer, 'EdgeColor', 'none');
set(ax2, 'XTick', 1:P.n, 'XTickLabel', compose('J%d', 1:P.n));
ylim(ax2, [-450 450]);

ax3 = axes('Parent', fig, 'Position', [0.600 0.195 0.360 0.255]);
style_axes(ax3, 'joint angles', 'frame', 'deg');
cols = [S.LM; S.transfer; S.hold; S.MS; S.J2];
hQ = gobjects(1, P.n);
for i = 1:P.n
    hQ(i) = plot(ax3, NaN, NaN, '-', 'Color', cols(i,:), 'LineWidth', 2.0);
end
xlim(ax3, [1 nF]); ylim(ax3, [-100 100]);

hud = annotate_hud(fig, 4, 'Free-flying 5R berthing arm  ·  kineto-statics and capture');

qHist = zeros(P.n, nF);
trail = nan(3, nF);
W1 = C.wrench1;

R = render_clip(fig, @frame, nF, '06_arm', C);

% ------------------------------------------------------------------ frame --
    function frame(k)
        if k <= nA
            q = D4.q_demo(:, iA(k));
            phaseName = 'STATICS SWEEP';
            tShow = (k-1) / C.videoFps;
            rateStr = 'SWEEP';
        else
            q = D6.q(:, iB(k-nA));
            phaseName = 'CAPTURE';
            tShow = D6.t(iB(k-nA));
            rateStr = 'x 2.5';
        end

        FK = fkine_5R(q, P);
        update_arm(hArm, FK);
        qHist(:,k) = q;

        N = system_jacobian_N(FK, P);
        Wc = contact_wrench(FK, P, W1.F, W1.M);
        tau = N.' * Wc.w;
        set(hBar, 'YData', tau(7:end).');

        fq = Wc.F_I / norm(Wc.F_I) * 1.8;
        set(hForce, 'XData', FK.p_EE(1), 'YData', FK.p_EE(2), 'ZData', FK.p_EE(3), ...
                    'UData', fq(1), 'VData', fq(2), 'WData', fq(3));

        for i = 1:P.n
            set(hQ(i), 'XData', 1:k, 'YData', rad2deg(qHist(i,1:k)));
        end

        if k > nA
            trail(:, k) = FK.p_EE;
            set(hTrail, 'XData', trail(1,:), 'YData', trail(2,:), 'ZData', trail(3,:));
            set(hTgt, 'Visible', 'on');
        end

        view(ax, 40 + 22*sin(2*pi*k/nF), 18 + 6*sin(4*pi*k/nF));
        camlight(hl, 'headlight');

        flash = '';
        if k <= 14
            flash = phaseName;
        elseif k == nA + 1 || (k > nA && k <= nA + 14)
            flash = 'CAPTURE';
        elseif k > nF - 18
            flash = 'CONTACT';
            set(hArm.ee, 'MarkerFaceColor', S.dock);
        end

        hud_set(hud, {sprintf('%5.1f s', tShow), sprintf('%.2f m', norm(FK.p_EE)), ...
                      sprintf('%.0f N m', max(abs(tau(7:end)))), rateStr}, ...
                {'SEQUENCE TIME', 'EE REACH', 'PEAK |\tau|', 'TIME RATE'}, flash);
    end
end
