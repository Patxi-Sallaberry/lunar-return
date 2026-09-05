function update_trail(h, X, Y, Z, i, iStart)
%UPDATE_TRAIL  Point a FADING_TRAIL at sample i of a path.
%
%   UPDATE_TRAIL(h, X, Y, [], i)          2-D
%   UPDATE_TRAIL(h, X, Y, Z, i)           3-D
%   UPDATE_TRAIL(h, X, Y, Z, i, iStart)   restrict the history to iStart..i
%
%   The full history is drawn once as a dim ghost line; the last h.tail samples
%   are split into h.nSeg contiguous chunks, brightest at the head. Chunks
%   overlap by one sample so the tail has no visible seams.

if nargin < 6 || isempty(iStart), iStart = 1; end
i = max(iStart, min(i, numel(X)));

if h.is3D
    set(h.ghost, 'XData', X(iStart:i), 'YData', Y(iStart:i), 'ZData', Z(iStart:i));
else
    set(h.ghost, 'XData', X(iStart:i), 'YData', Y(iStart:i));
end

i0 = max(iStart, i - h.tail + 1);
edges = round(linspace(i0, i, h.nSeg + 1));

for k = 1:h.nSeg
    a = edges(k);
    b = edges(k+1);
    if b <= a
        idx = [];
    else
        idx = a:b;                        % one-sample overlap, no seams
    end
    if isempty(idx)
        if h.is3D
            set(h.seg(k), 'XData', NaN, 'YData', NaN, 'ZData', NaN);
        else
            set(h.seg(k), 'XData', NaN, 'YData', NaN);
        end
    elseif h.is3D
        set(h.seg(k), 'XData', X(idx), 'YData', Y(idx), 'ZData', Z(idx));
    else
        set(h.seg(k), 'XData', X(idx), 'YData', Y(idx));
    end
end
end
