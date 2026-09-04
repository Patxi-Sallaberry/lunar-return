function T = cubic_joint_traj(q0, qf, tf, t)
%CUBIC_JOINT_TRAJ  Rest-to-rest cubic interpolation in joint space.
%   T = CUBIC_JOINT_TRAJ(q0, qf, tf, t) returns T.q, T.qd, T.qdd sampled on t
%   (1xN), each nq x N. Boundary conditions q(0)=q0, q(tf)=qf, qd(0)=qd(tf)=0.
%
%   a0 = q0, a1 = 0, a2 = 3*dq/tf^2, a3 = -2*dq/tf^3.
%
%   Cubic rather than quintic on purpose: berthing rates are slow enough that
%   the discontinuous acceleration at the endpoints is harmless, and the
%   velocity profile stays trivially verifiable (zero at both ends).

q0 = q0(:); qf = qf(:);
t  = t(:).';
dq = qf - q0;

a0 = q0;
a1 = zeros(size(q0));
a2 =  3 * dq / tf^2;
a3 = -2 * dq / tf^3;

T.t   = t;
T.q   = a0 + a1.*t + a2.*(t.^2) + a3.*(t.^3);
T.qd  =      a1    + 2*a2.*t    + 3*a3.*(t.^2);
T.qdd =              2*a2       + 6*a3.*t;

T.coeffs = [a0, a1, a2, a3];
T.tf = tf;
end
