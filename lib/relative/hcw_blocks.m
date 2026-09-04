function [Prr, Prv, Pvr, Pvv] = hcw_blocks(t, n)
%HCW_BLOCKS  3x3 partition of the HCW state transition matrix.
%   [Prr, Prv, Pvr, Pvv] = HCW_BLOCKS(t, n) so that
%       dr(t) = Prr*dr0 + Prv*dv0
%       dv(t) = Pvr*dr0 + Pvv*dv0
%   Prv is the block that every targeting problem inverts.

Phi = phi_hcw(t, n);
Prr = Phi(1:3, 1:3);
Prv = Phi(1:3, 4:6);
Pvr = Phi(4:6, 1:3);
Pvv = Phi(4:6, 4:6);
end
