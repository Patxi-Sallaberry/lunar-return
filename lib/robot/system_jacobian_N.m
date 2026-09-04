function [N, Nl, Nd] = system_jacobian_N(FK, P)
%SYSTEM_JACOBIAN_N  Twist-propagation matrix of the free-flying 5R system.
%
%   [N, Nl, Nd] = SYSTEM_JACOBIAN_N(FK, P) builds the 36x11 map
%       t = N * u,   u = [omega0; rdot0; qdot(1:5)]      (11x1)
%   where t stacks the six-dimensional twists [omega; v] of the base and of
%   the five links, each taken at the body centre of mass.
%
%   N = Nl * Nd:
%     Nd = blkdiag(I6, p1, ..., p5) injects the generalised velocities into
%          the body they belong to, with p_i = [e_i; e_i x g_i] in inertial
%          coordinates and g_i the joint-to-CoM offset of link i.
%     Nl  is block lower triangular, unit diagonal, with rigid-body twist
%          transports B_ij = [I 0; skew(r_j - r_i) I] carrying the twist of
%          body j to body i.
%
%   Sign of the transport block: v_i = v_j + omega_j x (r_i - r_j), and
%   omega_j x d = -skew(d)*omega_j, hence skew(r_j - r_i) and not the reverse.
%   Getting this backwards produces a base reaction whose force is right and
%   whose moment is wrong, which the kineto-static tests catch.
%
%   Kineto-static duality: tau = N.' * w with w the stacked external wrenches
%   ordered [moment; force] to match the [omega; v] twist ordering.

nb = P.n + 1;                       % base + links
nq = P.n;
dim = 6 * nb;

% Body origins: body 1 is the base (taken at the arm mounting point), bodies
% 2..6 are the link centres of mass.
r = [P.p_mount, FK.r_c];

Nl = eye(dim);
for i = 1:nb
    for j = 1:i-1
        B = [ eye(3),               zeros(3);
              skew(r(:,j) - r(:,i)), eye(3) ];
        Nl(6*(i-1)+1 : 6*i, 6*(j-1)+1 : 6*j) = B;
    end
end

Nd = zeros(dim, 6 + nq);
Nd(1:6, 1:6) = eye(6);
for i = 1:nq
    e  = FK.z(:, i);                          % joint axis, inertial
    g  = FK.r_c(:, i) - FK.r_j(:, i);         % joint -> CoM, inertial
    Nd(6*i+1 : 6*i+6, 6+i) = [e; cross(e, g)];
end

N = Nl * Nd;
end
