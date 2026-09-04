function y = wrapTo360(x)
%WRAPTO360  Wrap an angle in degrees to [0, 360). Local copy so the repository
%   never depends on the Mapping or Aerospace toolboxes.

y = mod(x, 360);
y(y < 0) = y(y < 0) + 360;
end
