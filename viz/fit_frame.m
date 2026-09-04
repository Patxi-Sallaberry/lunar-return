function out = fit_frame(img, targetWH)
%FIT_FRAME  Force a captured frame to the exact encoder resolution.
%   out = FIT_FRAME(img, [W H])
%
%   Screen capture can come back one pixel short, or twice the size on a
%   HiDPI display. VideoWriter refuses a stream whose frame size changes, so
%   every frame is snapped to the target here with a nearest-neighbour
%   resample. Deliberately toolbox-free: imresize lives in Image Processing.

Wt = targetWH(1);
Ht = targetWH(2);
[H, W, ~] = size(img);

if H == Ht && W == Wt
    out = img;
    return
end

ri = max(1, min(H, round(linspace(1, H, Ht))));
ci = max(1, min(W, round(linspace(1, W, Wt))));
out = img(ri, ci, :);
end
