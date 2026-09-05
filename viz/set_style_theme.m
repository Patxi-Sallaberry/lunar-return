function old = set_style_theme(mode)
%SET_STYLE_THEME  Choose the palette STYLE() returns when called with no mode.
%   old = SET_STYLE_THEME('light')  switches and returns the previous theme
%   SET_STYLE_THEME('dark')         switches back
%
%   Stored on the root graphics object rather than in a persistent variable so
%   that every function in the process sees the same value, including the
%   drawing helpers that call STYLE() with no arguments.
%
%   Callers are expected to restore the previous theme, ideally with onCleanup,
%   so that a failed report export cannot leave the video renderer in light mode.

old = getappdata(0, 'lrr_style_theme');
if isempty(old), old = 'dark'; end
if nargin > 0 && ~isempty(mode)
    style(mode);                      % validates the name before committing
    setappdata(0, 'lrr_style_theme', lower(mode));
end
end
