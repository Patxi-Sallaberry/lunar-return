function [ok, msg] = test_fkine_reference_pose(C)
%TEST_FKINE_REFERENCE_POSE  Forward kinematics at theta = [0 45 0 60 0] deg.
%   With p_mount = 0 the chain must reproduce the reference end-effector frame
%   R = Ry(105 deg), p = [5.3052; 0; 4.5579] m.

P = manipulator_params(C);
FK = fkine_5R(deg2rad([0 45 0 60 0]).', P);

R_ref = [-0.2588 0  0.9659;
          0      1  0     ;
         -0.9659 0 -0.2588];
p_ref = [5.3052; 0; 4.5579];

eR = norm(FK.R_EE - R_ref);
eP = norm(FK.p_EE - p_ref);

okMount = norm(P.p_mount) < 1e-12;
ok = (eR < 2e-3) && (eP < 5e-3) && okMount;

msg = sprintf('|R-R_ref| = %.2e (tol 2e-3), |p-p_ref| = %.2e m, reach %.2f m', ...
              eR, eP, P.reach);
if ~okMount
    msg = [msg ' [p_mount is not zero, position check is not meaningful]'];
end
end
