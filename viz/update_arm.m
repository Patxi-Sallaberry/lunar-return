function update_arm(h, FK)
%UPDATE_ARM  Rewrite the vertex data of an arm drawn by DRAW_ARM.
%   UPDATE_ARM(h, FK). Keeping the same graphics objects across frames is the
%   difference between a clip that renders in seconds and one that renders in
%   minutes.

P = h.P;
pts = [FK.r_j, FK.p_EE];

for i = 1:P.n
    [X, Y, Z] = cylinder_mesh(pts(:, i), pts(:, i+1), P.Rcyl, 20);
    set(h.link(i), 'XData', X, 'YData', Y, 'ZData', Z);
end

set(h.joints, 'XData', FK.r_j(1,:), 'YData', FK.r_j(2,:), 'ZData', FK.r_j(3,:));
set(h.spine,  'XData', pts(1,:),    'YData', pts(2,:),    'ZData', pts(3,:));
set(h.ee,     'XData', FK.p_EE(1),  'YData', FK.p_EE(2),  'ZData', FK.p_EE(3));

axLen = 0.45;
for k = 1:3
    d = FK.R_EE(:,k) * axLen;
    set(h.triad(k), 'XData', FK.p_EE(1)+[0 d(1)], ...
                    'YData', FK.p_EE(2)+[0 d(2)], ...
                    'ZData', FK.p_EE(3)+[0 d(3)]);
end
end
