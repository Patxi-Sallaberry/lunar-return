function p = to_shell_path(p, mode)
%TO_SHELL_PATH  Translate a MATLAB path for the shell that will consume it.
%   p = TO_SHELL_PATH(p, 'wsl')    Windows / UNC path -> WSL path
%   p = TO_SHELL_PATH(p, 'native') unchanged
%
%   The repository is often checked out inside WSL and driven from a Windows
%   MATLAB, so a UNC path like \\wsl.localhost\Ubuntu\root\project has to
%   become /root/project before ffmpeg inside WSL can see it.

if nargin < 2, mode = 'native'; end
if ~strcmpi(mode, 'wsl')
    return
end

p = strrep(p, '\', '/');

tok = regexp(p, '^//wsl(?:\.localhost|\$)/[^/]+(/.*)$', 'tokens', 'once');
if ~isempty(tok)
    p = tok{1};
    return
end

tok = regexp(p, '^([A-Za-z]):(/.*)$', 'tokens', 'once');
if ~isempty(tok)
    p = ['/mnt/' lower(tok{1}) tok{2}];
end
end
