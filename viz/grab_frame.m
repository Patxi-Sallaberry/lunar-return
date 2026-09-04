function img = grab_frame(fig, targetWH)
%GRAB_FRAME  Capture one RGB frame from an off-screen figure.
%   img = GRAB_FRAME(fig, [W H])
%
%   getframe is tried first because it is by far the fastest path. On headless
%   Linux without a framebuffer it can return an empty or degenerate array, in
%   which case the print-to-image path is used instead. Both are snapped to
%   the encoder resolution by FIT_FRAME.

img = [];
try
    F = getframe(fig);
    img = F.cdata;
catch
    img = [];
end

if isempty(img) || size(img,1) < 16 || size(img,2) < 16
    img = print(fig, '-RGBImage', '-r0');
end

img = fit_frame(img, targetWH);
end
