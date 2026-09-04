function [ok, msg] = test_link_inertias(C)
%TEST_LINK_INERTIAS  Cylinder inertias against the design table (+-0.02).

P = manipulator_params(C);

Ixx_ref = [1.07 85.89 56.01 0.71 0.40];
Izz_ref = [0.34  1.13  0.96 0.23 0.17];

eX = max(abs(P.Ixx - Ixx_ref));
eZ = max(abs(P.Izz - Izz_ref));

ok = (eX <= 0.02) && (eZ <= 0.02);
msg = sprintf('max |dIxx| = %.4f, max |dIzz| = %.4f (tol 0.02), total mass %.0f kg', ...
              eX, eZ, P.mTotal);
end
