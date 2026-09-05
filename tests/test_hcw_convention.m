function [ok, msg] = test_hcw_convention(C)
%TEST_HCW_CONVENTION  Lock the HCW frame down with tests, not with a comment.
%
%   The linear relative dynamics used here measure +x ASTERN of the target,
%   which is the opposite of Fehse's +V-bar. That choice is defensible but it
%   is exactly the kind of thing that rots: someone reads "V-bar", assumes the
%   literature convention, and every sign in Part 2 is quietly wrong.
%
%   Five checks:
%     1. Phi(0) = I
%     2. Phi(t) Phi(-t) = I
%     3. dPhi/dt(0) = A, the system matrix. This is what pins the Coriolis
%        signs; the other checks pass for either convention.
%     4. Closed form equals a numerical integration of the same ODE, column by
%        column, at two epochs.
%     5. The two physical discriminators: a radial release must drift the way
%        the written convention says, and the reference injection error must
%        reproduce the independent implementation's hold delta-v.

if nargin < 1 || isempty(C), C = mission_constants(); end
n = C.n2;
fails = {};

% ------------------------------------------------------------- 1. identity --
e1 = norm(phi_hcw(0, n) - eye(6));
if e1 > 1e-12, fails{end+1} = sprintf('Phi(0) off by %.1e', e1); end

% ------------------------------------------------------------ 2. inverse ----
t2 = 1234.5;
e2 = norm(phi_hcw(t2, n) * phi_hcw(-t2, n) - eye(6));
if e2 > 1e-9, fails{end+1} = sprintf('Phi(t)Phi(-t) off by %.1e', e2); end

% -------------------------------------------------- 3. derivative at zero ---
A = hcw_system_matrix(n);
h = 1e-6;
e3 = norm((phi_hcw(h,n) - phi_hcw(-h,n))/(2*h) - A);
if e3 > 1e-4, fails{end+1} = sprintf('dPhi/dt(0) off by %.1e', e3); end

% ------------------------------------------- 4. closed form vs integration --
% One ode45 per column of the identity: if the closed form and the ODE agree,
% the matrix in the report and the matrix in the code are the same object.
opts = odeset('RelTol', 1e-12, 'AbsTol', 1e-14);
e4 = 0;
for tau = [0.3*2*pi, 6*pi]
    tf = tau / n;
    Pode = zeros(6);
    for col = 1:6
        x0 = zeros(6,1); x0(col) = 1;
        [~, X] = ode45(@(tt,xx) A*xx, [0 tf], x0, opts);
        Pode(:,col) = X(end,:).';
    end
    e4 = max(e4, max(abs(phi_hcw(tf, n) - Pode), [], 'all'));
end
if e4 > 1e-8, fails{end+1} = sprintf('closed form vs ode45 off by %.1e', e4); end

% ------------------------------------------------ 5a. radial-release sign ---
% +z is radially outward: higher orbit, slower, must fall behind. In this
% frame "behind" is +x, so a positive answer is the physically correct one.
xDrift = [1 0 0 0 0 0] * phi_hcw(3*C.T2, n) * [0;0;100;0;0;0];
if xDrift <= 0
    fails{end+1} = sprintf('radial release drifts %+.0f m: sign contradicts the astern convention', xDrift);
end
if abs(xDrift) < 11.0e3 || abs(xDrift) > 11.6e3
    fails{end+1} = sprintf('radial-release drift %.2f km outside [11.0, 11.6]', abs(xDrift)/1e3);
end

% ------------------------------------------- 5b. reference cross-check ------
dr0 = [207.6; -126.1; 634.6];
dv0 = [0.0087; 0.1478; 0.2944];
H = two_impulse_hold(dr0, dv0, C.r_hold, C.v_hold, C.dt_tr, n);
if H.dV_total < 0.5 || H.dV_total > 3
    fails{end+1} = sprintf('reference hold dV = %.3f m/s, outside [0.5, 3]', H.dV_total);
end

% The mirrored reading is recorded so the choice stays auditable: it must NOT
% be the one that matches, otherwise the convention paragraph is wrong.
Hm = two_impulse_hold([-dr0(1); dr0(2:3)], [-dv0(1); dv0(2:3)], ...
                      C.r_hold, C.v_hold, C.dt_tr, n);
if abs(Hm.dV_total - 1.4) < abs(H.dV_total - 1.4)
    fails{end+1} = 'the mirrored frame matches the reference better: convention paragraph is wrong';
end

% ------------------------------------------------------------- vectorised ---
tv = [0, 100, 2000];
Pv = phi_hcw(tv, n);
e6 = 0;
for k = 1:numel(tv)
    e6 = max(e6, norm(Pv(:,:,k) - phi_hcw(tv(k), n)));
end
if ~isequal(size(Pv), [6 6 3]) || e6 > 0
    fails{end+1} = 'vectorised phi_hcw disagrees with the scalar call';
end

ok = isempty(fails);
if ok
    msg = sprintf(['Phi(0) %.0e, Phi(t)Phi(-t) %.0e, dPhi/dt %.0e, vs ode45 %.0e, ' ...
                   'radial drift %+.2f km, ref hold %.3f m/s (mirrored %.3f)'], ...
                   e1, e2, e3, e4, xDrift/1e3, H.dV_total, Hm.dV_total);
else
    msg = strjoin(fails, '; ');
end
end

function A = hcw_system_matrix(n)
%HCW_SYSTEM_MATRIX  First-order form of the astern-positive HCW equations.
%   xdd - 2n zdot = 0 ; ydd + n^2 y = 0 ; zdd + 2n xdot - 3n^2 z = 0
A = [ 0     0      0     1     0    0;
      0     0      0     0     1    0;
      0     0      0     0     0    1;
      0     0      0     0     0  2*n;
      0  -n^2      0     0     0    0;
      0     0  3*n^2  -2*n     0    0 ];
end
