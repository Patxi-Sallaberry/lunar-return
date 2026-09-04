function R = rot_axis_angle(e, th)
%ROT_AXIS_ANGLE  Euler-Rodrigues rotation about a unit axis.
%   R = ROT_AXIS_ANGLE(e, th) = cos(th)*I + (1-cos(th))*e*e' + sin(th)*skew(e)
%
%   The axis is normalised defensively: a joint axis that drifts off unit norm
%   silently turns the rotation into a scaling, which is very hard to spot in
%   a forward-kinematics chain.

e = e(:);
n = norm(e);
if n < eps
    error('rot_axis_angle:axis', 'Rotation axis must be non-zero.');
end
e = e / n;

c = cos(th);
s = sin(th);
R = c * eye(3) + (1 - c) * (e * e.') + s * skew(e);
end
