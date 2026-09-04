function S = skew(a)
%SKEW  Skew-symmetric matrix such that SKEW(a)*b == cross(a, b).

S = [    0  -a(3)   a(2);
      a(3)     0   -a(1);
     -a(2)  a(1)      0 ];
end
