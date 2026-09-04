function s = hms(tsec)
%HMS  Format seconds as HH:MM:SS for the mission clock in the HUD.

tsec = max(0, tsec);
hh = floor(tsec / 3600);
mm = floor((tsec - 3600*hh) / 60);
ss = floor(tsec - 3600*hh - 60*mm);
s = sprintf('%02d:%02d:%02d', hh, mm, ss);
end
