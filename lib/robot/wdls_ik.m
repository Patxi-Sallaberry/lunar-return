function S = wdls_ik(q0, p_target, R_target, P, opts)
%WDLS_IK  Weighted damped least-squares inverse kinematics for the 5R arm.
%
%   S = WDLS_IK(q0, p_target, R_target, P, opts) iterates
%       q <- q + alpha * (J'*W*J + lambda^2*I)^{-1} * J'*W*dx
%   with dx = [p_target - p; e_o] and the Siciliano orientation error
%       e_o = 0.5*(x x x_t + y x y_t + z x z_t)
%
%   Axis-angle extraction is deliberately avoided: it is singular at +-180 deg
%   and the seed poses used here are far from the target, so large rotations
%   do occur on the first iterations.
%
%   A 5R arm cannot serve all six task DOF. W de-weights the component the
%   wrist cannot produce (default diag([1 1 1 1 1 0.01])), so the solver
%   spends its redundancy on position first and accepts a residual attitude.
%
%   opts fields: lambda, alpha, W, maxIter, tolPos.

if nargin < 5, opts = struct(); end
lambda  = getf(opts, 'lambda', 0.05);
alpha   = getf(opts, 'alpha', 0.4);
W       = getf(opts, 'W', diag([1 1 1 1 1 0.01]));
maxIter = getf(opts, 'maxIter', 200);
tolPos  = getf(opts, 'tolPos', 1e-3);

q = q0(:);
nq = numel(q);

S.q_hist   = zeros(nq, maxIter+1);
S.err_pos  = zeros(1, maxIter+1);
S.err_ori  = zeros(1, maxIter+1);
S.q_hist(:,1) = q;

S.converged     = false;
S.iterConverged = NaN;

for k = 1:maxIter+1
    FK = fkine_5R(q, P);
    dp = p_target(:) - FK.p_EE;
    eo = 0.5 * ( cross(FK.R_EE(:,1), R_target(:,1)) + ...
                 cross(FK.R_EE(:,2), R_target(:,2)) + ...
                 cross(FK.R_EE(:,3), R_target(:,3)) );

    S.err_pos(k) = norm(dp);
    S.err_ori(k) = norm(eo);
    S.q_hist(:,k) = q;

    if S.err_pos(k) < tolPos && ~S.converged
        S.converged     = true;
        S.iterConverged = k - 1;      % iterations actually taken
        break
    end
    if k > maxIter
        break
    end

    J  = geometric_jacobian(FK);
    dx = [dp; eo];
    q  = q + alpha * ((J.'*W*J + lambda^2*eye(nq)) \ (J.'*W*dx));
end

S.iters   = k - 1;
S.q       = q;
S.q_hist  = S.q_hist(:, 1:k);
S.err_pos = S.err_pos(1:k);
S.err_ori = S.err_ori(1:k);
S.FK      = fkine_5R(q, P);
S.err_pos_final = S.err_pos(end);
S.err_ori_final = S.err_ori(end);
end

function v = getf(s, f, d)
if isfield(s, f) && ~isempty(s.(f)), v = s.(f); else, v = d; end
end
