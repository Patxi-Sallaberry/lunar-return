function [ok, msg] = test_cubic_traj(C)
%TEST_CUBIC_TRAJ  Boundary conditions of the rest-to-rest cubic.

q0 = zeros(5,1);
qf = deg2rad([40; 35; -20; 50; 25]);
tf = C.ik_tf;
t  = linspace(0, tf, 401);

T = cubic_joint_traj(q0, qf, tf, t);

e0  = norm(T.q(:,1)   - q0);
ef  = norm(T.q(:,end) - qf);
v0  = norm(T.qd(:,1));
vf  = norm(T.qd(:,end));

% Analytical peak rate of a rest-to-rest cubic is 1.5*dq/tf at mid-time.
vPeakRef = max(abs(1.5 * (qf - q0) / tf));
ePeak = abs(max(abs(T.qd(:))) - vPeakRef);

ok = (e0 < 1e-12) && (ef < 1e-12) && (v0 < 1e-12) && (vf < 1e-12) && (ePeak < 1e-6);
msg = sprintf('q(0) %.1e, q(tf) %.1e, qd(0) %.1e, qd(tf) %.1e, peak-rate %.1e', ...
              e0, ef, v0, vf, ePeak);
end
