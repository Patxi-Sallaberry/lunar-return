function S = style(mode)
%STYLE  Palette shared by every figure and video frame.
%   S = STYLE()        the currently selected theme
%   S = STYLE('dark')  the mission-control theme used by the video and README
%   S = STYLE('light') an academic theme for the printed report
%
%   Two channels, two looks, one palette structure: every drawing helper reads
%   the same field names, so switching theme never touches a plotting call.
%   SET_STYLE_THEME changes the default for subsequent calls.
%
%   Hex values for the dark theme, for anyone matching the look elsewhere:
%   bg #0B0F14, panel #121821, LM #3DBBFF, MS #FF5A4A, transfer #3DFF8A,
%   J2 #C889FF, hold #FFD166, text #E8EEF4, mute #8B98A8.

persistent cacheDark cacheLight
if nargin < 1 || isempty(mode)
    mode = getappdata(0, 'lrr_style_theme');
    if isempty(mode), mode = 'dark'; end
end

switch lower(mode)
    case 'dark'
        if ~isempty(cacheDark), S = cacheDark; return, end
        S = dark_palette();
        S.font = pick_font();
        S.mono = pick_mono();
        S = sizes(S);
        cacheDark = S;
    case 'light'
        if ~isempty(cacheLight), S = cacheLight; return, end
        S = light_palette();
        S.font = pick_font();
        S.mono = pick_mono();
        S = sizes(S);
        cacheLight = S;
    otherwise
        error('style:mode', 'Unknown theme "%s".', mode);
end
end

% ------------------------------------------------------------------ themes --
function S = dark_palette()
S.theme     = 'dark';
S.bg        = hex2rgb('0B0F14');
S.panel     = hex2rgb('121821');
S.moonFace  = [0.55 0.55 0.58];
S.moonEdge  = [0.25 0.25 0.28];
S.crater    = [0.46 0.46 0.50];
S.LM        = hex2rgb('3DBBFF');
S.MS        = hex2rgb('FF5A4A');
S.transfer  = hex2rgb('3DFF8A');
S.hold      = hex2rgb('FFD166');
S.dock      = [1.00 1.00 1.00];
S.J2        = hex2rgb('C889FF');
S.third     = hex2rgb('4FC3E8');
S.text      = hex2rgb('E8EEF4');
S.dim       = hex2rgb('8B98A8');
S.gridCol   = [1 1 1];
S.gridAlpha = 0.08;
S.accent    = hex2rgb('3DFF8A');
S.warn      = hex2rgb('FF8A3D');
end

function S = light_palette()
%LIGHT_PALETTE  For the printed report. Same roles, print-safe saturation.
S.theme     = 'light';
S.bg        = [1 1 1];
S.panel     = [0.965 0.972 0.980];
S.moonFace  = [0.82 0.82 0.85];
S.moonEdge  = [0.45 0.45 0.50];
S.crater    = [0.72 0.72 0.76];
S.LM        = [0.06 0.35 0.72];
S.MS        = [0.78 0.16 0.10];
S.transfer  = [0.06 0.50 0.22];
S.hold      = [0.72 0.50 0.02];
S.dock      = [0.10 0.10 0.12];
S.J2        = [0.45 0.16 0.62];
S.third     = [0.08 0.42 0.56];
S.text      = [0.10 0.12 0.15];
S.dim       = [0.34 0.37 0.42];
S.gridCol   = [0 0 0];
S.gridAlpha = 0.13;
S.accent    = [0.06 0.35 0.72];
S.warn      = [0.78 0.36 0.02];
end

function S = sizes(S)
if strcmp(S.theme, 'light')
    % Report figures are exported wide and then scaled down to a 160 mm text
    % block, so point sizes shrink by roughly a third on the page and the dark
    % theme's 12 pt would land near 4 pt. They are enlarged here to compensate.
    %
    % Pass 2 over-corrected to 30/24/20 and the axes positions, which were laid
    % out for the dark sizes, could no longer hold the text: titles collided and
    % legends were clipped in the CR3BP and inverse-kinematics figures. These
    % values land around 6-8 pt on the page, which is readable next to 11 pt
    % body text without reflowing any layout.
    S.fsTitle = 20;
    S.fsAxis  = 18;
    S.fsHud   = 18;
    S.fsSmall = 16;
    S.lw      = 2.2;
else
    S.fsTitle = 20;
    S.fsAxis  = 14;
    S.fsHud   = 17;
    S.fsSmall = 12;
    S.lw      = 1.8;
end
end

function f = pick_font()
%PICK_FONT  First proportional family that actually exists on this machine.
f = first_available({'Helvetica Neue', 'Helvetica', 'Arial', ...
                     'DejaVu Sans', 'Liberation Sans'}, 'Helvetica');
end

function f = pick_mono()
%PICK_MONO  Monospace family for HUD numerals.
%   Telemetry that changes every frame must not reflow. A proportional font
%   makes "11:09:58" jitter horizontally as the digits change width, which
%   reads as a rendering glitch at 30 fps.
f = first_available({'Consolas', 'DejaVu Sans Mono', 'Liberation Mono', ...
                     'Menlo', 'Courier New'}, 'Courier New');
end

function f = first_available(candidates, fallback)
f = fallback;
try
    have = listfonts;
    for c = candidates
        if any(strcmpi(have, c{1})), f = c{1}; return, end
    end
catch
    % listfonts is unavailable in some headless configurations.
end
end

function c = hex2rgb(h)
c = [hex2dec(h(1:2)) hex2dec(h(3:4)) hex2dec(h(5:6))] / 255;
end
