function dx = cr3bp_eom(~, x, mu)
%CR3BP_EOM  Circular restricted three-body equations in the synodic frame.
%   dx = CR3BP_EOM(t, x, mu) with x = [r(1:3); v(1:3)] non-dimensional,
%   barycentric, rotating at unit angular rate about +z.
%
%   Primary 1 (Earth) sits at x = -mu, primary 2 (Moon) at x = 1-mu.
%   Lengths are in LU = dEM, times in TU = sqrt(LU^3/(muEarth+muMoon)).

r = x(1:3);
v = x(4:6);

d1 = [r(1) + mu;     r(2); r(3)];      % vector from Earth
d2 = [r(1) - 1 + mu; r(2); r(3)];      % vector from Moon
r1 = norm(d1);
r2 = norm(d2);

a = [ 2*v(2) + r(1);
     -2*v(1) + r(2);
      0 ] ...
    - (1-mu) * d1 / r1^3 ...
    -  mu    * d2 / r2^3;

dx = [v; a];
end
