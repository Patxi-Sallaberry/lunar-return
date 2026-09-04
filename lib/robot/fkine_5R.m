function FK = fkine_5R(q, P)
%FKINE_5R  Forward kinematics of the 5R berthing arm.
%   FK = FKINE_5R(q, P) with q a 5-vector of joint angles [rad] and P from
%   MANIPULATOR_PARAMS. Returns
%       FK.r_j   3x5  joint origins in inertial coordinates
%       FK.r_c   3x5  link centres of mass
%       FK.z     3x5  joint axes in inertial coordinates
%       FK.R     3x3x5 cumulative link orientations
%       FK.T     4x4x5 cumulative link frames (origin at the CoM)
%       FK.T_EE  4x4  end-effector frame at the TIP of link 5
%       FK.p_EE, FK.R_EE
%
%   Chain: T_i = T_{i-1} * Trans(b_{i-1}) * Rot(e_i, q_i) * Trans(g_i), with
%   b_0 = 0 so joint 1 sits at the mounting point. With p_mount = 0 and
%   q = [0 45 0 60 0] deg this reproduces the reference end-effector pose
%   R_EE = Ry(105 deg), p_EE = [5.305; 0; 4.558] m.

q = q(:);
n = P.n;

FK.r_j = zeros(3, n);
FK.r_c = zeros(3, n);
FK.z   = zeros(3, n);
FK.R   = zeros(3, 3, n);
FK.T   = zeros(4, 4, n);

T = ht(eye(3), P.p_mount);

for i = 1:n
    if i == 1
        b = [0; 0; 0];                 % mount point IS joint 1
    else
        b = P.b(:, i-1);               % previous CoM -> this joint
    end

    T = T * ht(eye(3), b);
    FK.r_j(:, i) = T(1:3, 4);

    % The axis is invariant under the rotation about itself, so it can be
    % mapped into inertial coordinates before applying the joint angle.
    FK.z(:, i) = T(1:3, 1:3) * P.axes(:, i);

    T = T * ht(rot_axis_angle(P.axes(:, i), q(i)), [0; 0; 0]);
    FK.R(:, :, i) = T(1:3, 1:3);

    T = T * ht(eye(3), P.g(:, i));     % joint -> CoM
    FK.r_c(:, i) = T(1:3, 4);
    FK.T(:, :, i) = T;
end

% End effector: one more half-link beyond CoM_5, i.e. the physical tip.
FK.T_EE = T * ht(eye(3), P.g(:, n));
FK.p_EE = FK.T_EE(1:3, 4);
FK.R_EE = FK.T_EE(1:3, 1:3);

FK.q = q;
end
