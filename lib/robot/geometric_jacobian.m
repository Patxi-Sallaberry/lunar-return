function J = geometric_jacobian(FK)
%GEOMETRIC_JACOBIAN  6x5 end-effector Jacobian of the 5R arm.
%   J = GEOMETRIC_JACOBIAN(FK) maps joint rates to the end-effector twist
%   ordered as [linear; angular]:
%       [v_EE; omega_EE] = J * qdot
%   Column i = [ z_i x (p_EE - r_i) ; z_i ] for a revolute joint.
%
%   NOTE the ordering. Part 6 uses [linear; angular] because the spatial error
%   is written [dp; e_o]. Part 4 uses the opposite convention [angular;
%   linear] for twists and [moment; force] for wrenches, which is the natural
%   one for the twist-propagation matrix N. Both are internally consistent and
%   the unit tests cross-check them against each other.

n = size(FK.r_j, 2);
J = zeros(6, n);
for i = 1:n
    J(1:3, i) = cross(FK.z(:, i), FK.p_EE - FK.r_j(:, i));
    J(4:6, i) = FK.z(:, i);
end
end
