function F = find_ffmpeg()
%FIND_FFMPEG  Locate a usable ffmpeg, natively or through WSL.
%   F = FIND_FFMPEG() returns
%       F.found   logical
%       F.prefix  command prefix, e.g. 'ffmpeg' or 'wsl -e ffmpeg'
%       F.mode    'native' | 'wsl' | 'none'   (also the TO_SHELL_PATH mode)
%
%   Cached: probing the shell is slow and the answer cannot change mid-build.

persistent cached
if ~isempty(cached)
    F = cached;
    return
end

F = struct('found', false, 'prefix', '', 'mode', 'none');

[st, ~] = sys_quiet('ffmpeg -version');
if st == 0
    F.found = true; F.prefix = 'ffmpeg'; F.mode = 'native';
    cached = F; return
end

if ispc
    [st, ~] = sys_quiet('wsl -e ffmpeg -version');
    if st == 0
        F.found = true; F.prefix = 'wsl -e ffmpeg'; F.mode = 'wsl';
        cached = F; return
    end
end

cached = F;
end
