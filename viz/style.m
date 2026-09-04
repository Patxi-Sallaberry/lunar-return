function S = style()
%STYLE  Dark engineering palette shared by every figure and video frame.
%   S = STYLE() returns colours, the resolved font family and a few layout
%   constants. Colours are chosen so the same asset reads correctly in a
%   GitHub README (light or dark) and in a LinkedIn video player.

persistent cached
if ~isempty(cached)
    S = cached;
    return
end

S.bg        = [0.05 0.07 0.10];
S.panel     = [0.08 0.10 0.14];
S.moonFace  = [0.55 0.55 0.58];
S.moonEdge  = [0.25 0.25 0.28];
S.crater    = [0.46 0.46 0.50];
S.LM        = [0.20 0.65 1.00];
S.MS        = [1.00 0.35 0.30];
S.transfer  = [0.35 0.90 0.45];
S.hold      = [1.00 0.85 0.20];
S.dock      = [1.00 1.00 1.00];
S.J2        = [0.85 0.45 1.00];
S.third     = [0.40 0.80 0.95];
S.text      = [0.92 0.93 0.95];
S.dim       = [0.60 0.64 0.70];
S.gridCol   = [1 1 1];
S.gridAlpha = 0.08;
S.accent    = [0.35 0.90 0.45];
S.warn      = [1.00 0.55 0.15];

% Font: take the first family that actually exists on this machine.
S.font = 'Helvetica';
try
    have = listfonts;
    for f = {'Helvetica Neue', 'Helvetica', 'Arial', 'DejaVu Sans', 'Liberation Sans'}
        if any(strcmpi(have, f{1}))
            S.font = f{1};
            break
        end
    end
catch
    % listfonts unavailable in some headless configurations; the default holds.
end

S.fsTitle = 20;
S.fsAxis  = 14;
S.fsHud   = 17;
S.fsSmall = 12;
S.lw      = 1.8;

cached = S;
end
