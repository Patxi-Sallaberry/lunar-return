function R = build_showreel(C, clipOrder)
%BUILD_SHOWREEL  Concatenate the clips into the portfolio reel.
%
%   R = BUILD_SHOWREEL(C) uses the standard seven-clip order.
%   R = BUILD_SHOWREEL(C, {'01_title', ...}) overrides it.
%
%   Writes results/video/clips/concat_list.txt, then calls ffmpeg to produce
%   showreel.mp4 (16:9) and showreel_square.mp4 (1080x1080 for the LinkedIn
%   feed), plus three README-sized GIFs. ffmpeg is looked up natively and,
%   on Windows, through WSL. If it is missing nothing is faked: the exact
%   command is printed so a human can finish the job in one paste.

if nargin < 2 || isempty(clipOrder)
    clipOrder = {'01_title','02_hohmann','03_proximity','04_perturbations', ...
                 '05_cr3bp','06_arm','07_endcard'};
end

R = struct('reel', false, 'square', false, 'gifs', 0, 'ffmpeg', 'missing', ...
           'missing_clips', {{}}, 'command', '');

present = {};
for k = 1:numel(clipOrder)
    f = fullfile(C.clipDir, [clipOrder{k} '.mp4']);
    if exist(f, 'file')
        present{end+1} = clipOrder{k}; %#ok<AGROW>
    else
        R.missing_clips{end+1} = clipOrder{k}; %#ok<AGROW>
    end
end

if isempty(present)
    fprintf('  showreel: no clips found, nothing to concatenate.\n');
    return
end

F = find_ffmpeg();
R.ffmpeg = F.mode;

% The concat demuxer needs paths in the syntax of the shell that runs it.
listFile = fullfile(C.clipDir, 'concat_list.txt');
fid = fopen(listFile, 'w');
for k = 1:numel(present)
    p = to_shell_path(fullfile(C.clipDir, [present{k} '.mp4']), F.mode);
    fprintf(fid, "file '%s'\n", p);
end
fclose(fid);

listS = to_shell_path(listFile, F.mode);
reelS = to_shell_path(fullfile(C.vidDir, 'showreel.mp4'), F.mode);
sqS   = to_shell_path(fullfile(C.vidDir, 'showreel_square.mp4'), F.mode);

cmdReel = sprintf(['%s -y -loglevel error -f concat -safe 0 -i "%s" ' ...
                   '-c:v libx264 -pix_fmt yuv420p -crf 18 -movflags +faststart "%s"'], ...
                   F.prefix, listS, reelS);
cmdSq = sprintf(['%s -y -loglevel error -i "%s" ' ...
                 '-vf "scale=1080:1080:force_original_aspect_ratio=increase,crop=1080:1080" ' ...
                 '-c:v libx264 -pix_fmt yuv420p -crf 18 -movflags +faststart "%s"'], ...
                 F.prefix, reelS, sqS);
R.command = cmdReel;

if ~F.found
    fprintf('  showreel: ffmpeg not found. Run this yourself:\n    %s\n', cmdReel);
    return
end

if sys_quiet(cmdReel) == 0
    R.reel = true;
    fprintf('  showreel.mp4 written (%d clips).\n', numel(present));
else
    fprintf('  showreel: ffmpeg concat failed.\n');
    return
end

if sys_quiet(cmdSq) == 0
    R.square = true;
    fprintf('  showreel_square.mp4 written (1080x1080).\n');
end

% README GIFs: 800 px wide, 12 fps, palette-optimised so they stay small.
for name = {'02_hohmann','03_proximity','06_arm'}
    src = fullfile(C.clipDir, [name{1} '.mp4']);
    if ~exist(src, 'file'), continue, end
    srcS = to_shell_path(src, F.mode);
    gifS = to_shell_path(fullfile(C.figDir, [name{1} '.gif']), F.mode);
    palS = to_shell_path(fullfile(C.frameDir, 'palette.png'), F.mode);
    c1 = sprintf('%s -y -loglevel error -i "%s" -vf "fps=12,scale=800:-1:flags=lanczos,palettegen" "%s"', ...
                 F.prefix, srcS, palS);
    c2 = sprintf(['%s -y -loglevel error -i "%s" -i "%s" ' ...
                  '-lavfi "fps=12,scale=800:-1:flags=lanczos [x]; [x][1:v] paletteuse" "%s"'], ...
                  F.prefix, srcS, palS, gifS);
    if sys_quiet(c1) == 0 && sys_quiet(c2) == 0
        R.gifs = R.gifs + 1;
    end
end
if R.gifs > 0
    fprintf('  %d README GIFs written to results/figures.\n', R.gifs);
end
end
