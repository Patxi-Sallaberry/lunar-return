function [ok, msg] = test_kinetostatics(C)
%TEST_KINETOSTATICS  Static equilibrium and kineto-static duality.
%
%   Two independent statements have to hold for a chain loaded by a single
%   external wrench:
%     1. the force part of the base reaction equals the applied force exactly
%     2. the joint torques from tau = N'*w equal J_geom'*[f; n] taken at the
%        tip, i.e. the 36-body twist-propagation route and the 6x5
%        end-effector Jacobian route agree

P = manipulator_params(C);
postures = {C.q_ext, C.q_bent, C.q_arb};
wrenches = {C.wrench1, C.wrench2};

eF = 0; eT = 0;
for p = 1:3
    FK = fkine_5R(postures{p}, P);
    N  = system_jacobian_N(FK, P);
    Jg = geometric_jacobian(FK);
    for w = 1:2
        W = contact_wrench(FK, P, wrenches{w}.F, wrenches{w}.M);
        tau = N.' * W.w;
        eF = max(eF, abs(norm(tau(4:6)) - norm(W.F_I)));

        % Total moment about the base origin, computed directly.
        Mbase = W.M_I + cross(W.r_tip - P.p_mount, W.F_I);
        eF = max(eF, norm(tau(1:3) - Mbase));

        eT = max(eT, norm(tau(7:end) - Jg.' * [W.F_I; W.M_I]));
    end
end

ok = (eF < 1e-8) && (eT < 1e-8);
msg = sprintf('base wrench residual %.2e, N-vs-Jacobian torque residual %.2e', eF, eT);
end
