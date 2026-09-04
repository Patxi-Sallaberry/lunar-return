function coe = rv2coe(r, v, mu)
%RV2COE  Classical orbital elements from a Cartesian state, degeneracy-safe.
%   coe = RV2COE(r, v, mu) returns a struct with fields
%       a  [km], e [-], i [deg], RAAN [deg], argp [deg], nu [deg],
%       h  [km^2/s], eps [km^2/s^2], u [deg] (argument of latitude)
%
%   The orbits in this project are circular AND equatorial, i.e. both classical
%   degeneracies at once. Rather than let omega and RAAN blow up we fall back
%   on the true longitude, which stays well defined:
%       - node vector vanishing  -> RAAN = 0, node direction taken as +x
%       - eccentricity vanishing -> argp = 0, nu measured from the node

r = r(:); v = v(:);
rn = norm(r);
vn = norm(v);

hv = cross(r, v);
h  = norm(hv);

ev = ((vn^2 - mu/rn) * r - dot(r, v) * v) / mu;
e  = norm(ev);

eps = vn^2/2 - mu/rn;
a   = -mu / (2*eps);

inc = acos(max(-1, min(1, hv(3)/h)));

nv = cross([0;0;1], hv);
nn = norm(nv);

tolN = 1e-10 * h;      % scale-aware: a node vector is O(h)
tolE = 1e-8;

if nn < tolN
    RAAN = 0;
    nhat = [1; 0; 0];              % equatorial: reference the +x axis
else
    RAAN = atan2(nv(2), nv(1));
    nhat = nv / nn;
end

% Argument of latitude, always defined for a non-degenerate orbit plane.
uu = atan2(dot(cross(nhat, r), hv/h), dot(nhat, r));

if e < tolE
    argp = 0;
    nu   = uu;                     % circular: true anomaly folds into u
else
    ehat = ev / e;
    argp = atan2(dot(cross(nhat, ehat), hv/h), dot(nhat, ehat));
    nu   = atan2(dot(cross(ehat, r), hv/h), dot(ehat, r));
end

coe = struct( ...
    'a',    a, ...
    'e',    e, ...
    'i',    wrapTo360(rad2deg(inc)), ...
    'RAAN', wrapTo360(rad2deg(RAAN)), ...
    'argp', wrapTo360(rad2deg(argp)), ...
    'nu',   wrapTo360(rad2deg(nu)), ...
    'u',    wrapTo360(rad2deg(uu)), ...
    'h',    h, ...
    'eps',  eps);
end
