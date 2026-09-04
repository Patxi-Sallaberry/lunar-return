function move_sc(h, r, vhat)
%MOVE_SC  Reposition a marker created by DRAW_SC without re-creating patches.
%   MOVE_SC(h, r, vhat). Re-using handles is what keeps the video render loop
%   from spending all its time in the graphics pipeline.

if nargin < 3 || isempty(vhat), vhat = [1; 0]; end
r = r(:);
vhat = vhat(:) / max(norm(vhat), eps);
Rz = [vhat(1) -vhat(2); vhat(2) vhat(1)];
s  = h.scale;

switch h.kind
    case 'LM'
        p = s * [ 1.6 -0.9 -0.9; 0 0.85 -0.85 ];
        set(h.body, 'XData', r(1) + Rz(1,:)*p, 'YData', r(2) + Rz(2,:)*p);
    case 'MS'
        p = s * [ 1.0 -1.0 -1.0 1.0; 0.6 0.6 -0.6 -0.6 ];
        set(h.body, 'XData', r(1) + Rz(1,:)*p, 'YData', r(2) + Rz(2,:)*p);
        w = s * [ -0.1 0.1 0.1 -0.1; 0.7 0.7 2.4 2.4 ];
        set(h.wing1, 'XData', r(1) + Rz(1,:)*w, 'YData', r(2) + Rz(2,:)*w);
        w(2,:) = -w(2,:);
        set(h.wing2, 'XData', r(1) + Rz(1,:)*w, 'YData', r(2) + Rz(2,:)*w);
end
end
