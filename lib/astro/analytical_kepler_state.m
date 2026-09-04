function [r, v] = analytical_kepler_state(t, leg)
%ANALYTICAL_KEPLER_STATE  Closed-form state on a circular or elliptical leg.
%   [r, v] = ANALYTICAL_KEPLER_STATE(t, leg) evaluates the exact Keplerian
%   solution at the times in the row vector t. Outputs are 3xN in km, km/s.
%
%   leg.type = 'circular'
%       leg.R       radius [km]
%       leg.n       mean motion [rad/s]
%       leg.theta0  argument of latitude at leg.t0 [rad]
%       leg.t0      epoch of theta0 [s]
%
%   leg.type = 'ellipse'
%       leg.a, leg.e, leg.mu
%       leg.t0      time of periapsis passage [s]
%       leg.omega   rotation of the perifocal frame about +z into MCI [rad]
%
%   This is the reference the ode45 propagation of Part 1 is validated
%   against; it is deliberately independent of any numerical integrator.

t = t(:).';
N = numel(t);
r = zeros(3, N);
v = zeros(3, N);

switch lower(leg.type)
    case 'circular'
        th = leg.theta0 + leg.n * (t - leg.t0);
        r  = leg.R * [cos(th); sin(th); zeros(1,N)];
        v  = leg.n * leg.R * [-sin(th); cos(th); zeros(1,N)];

    case 'ellipse'
        nH = sqrt(leg.mu / leg.a^3);
        M  = nH * (t - leg.t0);
        E  = kepler_E(M, leg.e);

        b  = leg.a * sqrt(1 - leg.e^2);
        rp = [ leg.a * (cos(E) - leg.e); b * sin(E); zeros(1,N) ];
        rn = leg.a * (1 - leg.e * cos(E));                 % radius from focus
        k  = sqrt(leg.mu * leg.a) ./ rn;
        vp = [ -k .* sin(E); (b/leg.a) * k .* cos(E); zeros(1,N) ];

        c = cos(leg.omega); s = sin(leg.omega);
        Rz = [c -s 0; s c 0; 0 0 1];
        r = Rz * rp;
        v = Rz * vp;

    otherwise
        error('analytical_kepler_state:type', 'Unknown leg type "%s".', leg.type);
end
end
