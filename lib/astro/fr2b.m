function dx = fr2b(~, x, mu)
%FR2B  Unperturbed two-body equations of motion.
%   dx = FR2B(t, x, mu) with x = [r(1:3); v(1:3)] in km and km/s.
%   The time argument is ignored: the field is autonomous.

r = x(1:3);
v = x(4:6);
dx = [v; -mu * r / norm(r)^3];
end
