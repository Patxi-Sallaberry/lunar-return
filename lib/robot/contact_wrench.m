function W = contact_wrench(FK, P, F_local, M_local)
%CONTACT_WRENCH  External berthing wrench, transported to the link-5 CoM.
%
%   W = CONTACT_WRENCH(FK, P, F_local, M_local) takes the contact force and
%   moment expressed in the end-effector frame and returns
%       W.w      36x1 stacked body wrenches, ordered [moment; force] per body
%       W.F_I    contact force in inertial coordinates
%       W.M_I    contact moment in inertial coordinates, at the tip
%       W.M_com  the same moment transported to the centre of mass of link 5
%
%   Only the end-effector body carries an external wrench; every other body
%   entry is zero. Micro-gravity, so no weight terms.

F_I = FK.R_EE * F_local(:);
M_I = FK.R_EE * M_local(:);

r_tip  = FK.p_EE;
r_com5 = FK.r_c(:, P.n);
M_com  = M_I + cross(r_tip - r_com5, F_I);

nb  = P.n + 1;
w   = zeros(6*nb, 1);
w(6*P.n + 1 : 6*P.n + 6) = [M_com; F_I];    % last block = link 5

W.w      = w;
W.F_I    = F_I;
W.M_I    = M_I;
W.M_com  = M_com;
W.r_tip  = r_tip;
W.r_com5 = r_com5;
end
