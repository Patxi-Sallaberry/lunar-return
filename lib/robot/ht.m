function T = ht(R, p)
%HT  4x4 homogeneous transform from a rotation and a translation.
%   T = HT(R, p). With one argument, HT(p) is a pure translation.

if nargin == 1
    p = R;
    R = eye(3);
end
T = [R, p(:); 0 0 0 1];
end
