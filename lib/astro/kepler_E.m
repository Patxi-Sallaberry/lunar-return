function [E, iters] = kepler_E(M, e, tol, maxIter)
%KEPLER_E  Solve Kepler's equation M = E - e*sin(E) by Newton-Raphson.
%   E = KEPLER_E(M, e) returns the eccentric anomaly in radians.
%   [E, iters] = KEPLER_E(M, e, tol, maxIter) exposes the tolerance (default
%   1e-14) and the iteration cap (default 100).
%
%   M may be an array; e is scalar. The starting guess follows the usual
%   e < 0.8 rule, which converges quadratically for the near-circular transfer
%   ellipse used here (e ~ 0.075).

if nargin < 3 || isempty(tol),     tol = 1e-14; end
if nargin < 4 || isempty(maxIter), maxIter = 100; end

M = mod(M, 2*pi);
if e < 0.8
    E = M;
else
    E = pi * ones(size(M));
end

iters = 0;
for k = 1:maxIter
    f  = E - e*sin(E) - M;
    fp = 1 - e*cos(E);
    dE = -f ./ fp;
    E  = E + dE;
    iters = k;
    if max(abs(dE)) < tol
        break
    end
end
end
