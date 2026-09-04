function [ok, msg] = test_hcw_stm_identity(C)
%TEST_HCW_STM_IDENTITY  Phi(0) = I and dPhi/dt(0) = A for the HCW system.
%
%   The second half is the check that actually catches sign errors: the
%   derivative of the closed-form STM at t = 0 must reproduce the system
%   matrix of the first-order form, including the Coriolis signs of this
%   project's non-standard axis convention.

n = C.n2;

e1 = norm(phi_hcw(0, n) - eye(6));

A = [ 0 0 0        1 0 0;
      0 0 0        0 1 0;
      0 0 0        0 0 1;
      0 0 0        0 0 2*n;
      0 -n^2 0     0 0 0;
      0 0 3*n^2   -2*n 0 0 ];

h = 1e-6;
dPhi = (phi_hcw(h, n) - phi_hcw(-h, n)) / (2*h);
e2 = norm(dPhi - A);

% A round trip through the STM must also be exactly invertible.
t = 1234.5;
e3 = norm(phi_hcw(t, n) * phi_hcw(-t, n) - eye(6));

ok = (e1 < 1e-12) && (e2 < 1e-4) && (e3 < 1e-9);
msg = sprintf('|Phi(0)-I| = %.2e, |dPhi/dt(0)-A| = %.2e, |Phi(t)Phi(-t)-I| = %.2e', ...
              e1, e2, e3);
end
