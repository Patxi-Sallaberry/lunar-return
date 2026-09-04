function hud_set(h, values, labels, flashText)
%HUD_SET  Update the three telemetry slots and the event flash.
%   HUD_SET(h, {'02:14:08','14.2 km','60.5 m/s'})
%   HUD_SET(h, values, labels)               also relabels the slots
%   HUD_SET(h, values, labels, 'DOCK')       shows the centre flash
%   Pass '' as flashText (or omit it) to hide the flash.

for k = 1:min(4, numel(values))
    set(h.slotValue(k), 'String', values{k});
end
if nargin >= 3 && ~isempty(labels)
    for k = 1:min(4, numel(labels))
        set(h.slotLabel(k), 'String', labels{k});
    end
end
if nargin >= 4 && ~isempty(flashText)
    set(h.flash, 'String', flashText, 'Visible', 'on');
else
    set(h.flash, 'Visible', 'off');
end
end
