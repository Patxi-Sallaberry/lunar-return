function P = manipulator_params(C)
%MANIPULATOR_PARAMS  Geometry and inertia of the 5R berthing arm.
%   P = MANIPULATOR_PARAMS(C) builds the parameter struct from the constants.
%
%   Each link is a homogeneous cylinder of radius R_cyl with its local z axis
%   along the link, so the centre of mass sits at mid-length:
%       Izz = 0.5*m*R^2                     (about the link axis)
%       Ixx = Iyy = m*(3*R^2 + L^2)/12      (transverse)
%
%   Offsets are pure z translations: g_i from joint i to CoM i, b_i from CoM i
%   to joint i+1, both equal to L_i/2.

P.n     = numel(C.armL);
P.L     = C.armL(:).';
P.m     = C.armM(:).';
P.Rcyl  = C.armR;
P.axes  = C.armAxes;              % 3xn, column i = joint axis in local frame
P.p_mount = C.p_mount(:);

P.g = [zeros(2, P.n); P.L/2];     % joint i  -> CoM i
P.b = [zeros(2, P.n); P.L/2];     % CoM i    -> joint i+1

P.Izz = 0.5 * P.m .* P.Rcyl^2;
P.Ixx = P.m .* (3*P.Rcyl^2 + P.L.^2) / 12;
P.Iyy = P.Ixx;

P.I = zeros(3,3,P.n);
for i = 1:P.n
    P.I(:,:,i) = diag([P.Ixx(i), P.Iyy(i), P.Izz(i)]);
end

P.mTotal = sum(P.m);
P.reach  = sum(P.L);              % 7.7 m fully extended

% Mothership bus, drawn only. The base pose is held fixed in Parts 4 and 6
% (free-flying assumption), so it never enters the kinematics.
P.busEdge   = C.msCube;
P.busCenter = C.msCubeCenter(:);
end
