function h = draw_sc(ax, r, kind, scale, vhat)
%DRAW_SC  Schematic spacecraft marker in a 2-D axes.
%   h = DRAW_SC(ax, r, kind, scale, vhat)
%     kind  'LM' -> triangle pointing along vhat (the ascent module)
%           'MS' -> rounded bus with two solar wings (the mothership)
%     scale characteristic size in data units
%     vhat  2-vector heading; defaults to +x
%
%   Returns a struct of handles whose XData/YData can be rewritten each video
%   frame, which is far cheaper than deleting and re-creating the patches.

if nargin < 4 || isempty(scale), scale = 1; end
if nargin < 5 || isempty(vhat),  vhat = [1; 0]; end
S = style();

r = r(:);
vhat = vhat(:) / max(norm(vhat), eps);
Rz = [vhat(1) -vhat(2); vhat(2) vhat(1)];

switch upper(kind)
    case 'LM'
        p = scale * [ 1.6 -0.9 -0.9; 0 0.85 -0.85 ];
        h.body = patch(ax, r(1) + Rz(1,:)*p, r(2) + Rz(2,:)*p, S.LM, ...
                       'EdgeColor', 'w', 'LineWidth', 0.8);
    case 'MS'
        p = scale * [ 1.0 -1.0 -1.0 1.0; 0.6 0.6 -0.6 -0.6 ];
        h.body = patch(ax, r(1) + Rz(1,:)*p, r(2) + Rz(2,:)*p, S.MS, ...
                       'EdgeColor', 'w', 'LineWidth', 0.8);
        w = scale * [ -0.1 0.1 0.1 -0.1; 0.7 0.7 2.4 2.4 ];
        h.wing1 = patch(ax, r(1) + Rz(1,:)*w, r(2) + Rz(2,:)*w, S.third, ...
                        'EdgeColor','none','FaceAlpha',0.8);
        w2 = w; w2(2,:) = -w2(2,:);
        h.wing2 = patch(ax, r(1) + Rz(1,:)*w2, r(2) + Rz(2,:)*w2, S.third, ...
                        'EdgeColor','none','FaceAlpha',0.8);
    otherwise
        error('draw_sc:kind', 'kind must be ''LM'' or ''MS''.');
end
h.kind  = upper(kind);
h.scale = scale;
end
