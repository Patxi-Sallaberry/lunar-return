function R = render_clip(fig, frameFcn, nFrames, clipName, C)
%RENDER_CLIP  Drive a frame callback and encode the result to MP4.
%
%   R = RENDER_CLIP(fig, frameFcn, nFrames, clipName, C)
%     frameFcn(k)  draws frame k into fig; it must MUTATE existing graphics
%                  objects, not rebuild the scene
%     clipName     base name, e.g. '02_hohmann'; the file lands in
%                  results/video/clips/<clipName>.mp4
%
%   Three encoder tiers, tried in order, so a missing codec degrades the
%   deliverable instead of destroying it:
%     1. VideoWriter with the MPEG-4 profile
%     2. PNG frame sequence piped through ffmpeg (native or WSL)
%     3. PNG frame sequence kept on disk, clip still counted as produced
%
%   R.status is 'mp4' | 'ffmpeg' | 'frames' | 'failed'.

S = style();
R = struct('name', clipName, 'status', 'failed', 'file', '', ...
           'frames', nFrames, 'seconds', nFrames / C.videoFps, ...
           'elapsed', 0, 'note', '');
tic;

if ~exist(C.clipDir, 'dir'), mkdir(C.clipDir); end
outFile = fullfile(C.clipDir, [clipName '.mp4']);

vw = [];
useVW = false;
try
    vw = VideoWriter(outFile, 'MPEG-4');
    vw.FrameRate = C.videoFps;
    vw.Quality   = 95;
    open(vw);
    useVW = true;
catch ME
    R.note = ['VideoWriter MPEG-4 unavailable: ' ME.message];
end

frameDir = fullfile(C.frameDir, clipName);
if ~useVW
    if exist(frameDir, 'dir'), rmdir(frameDir, 's'); end
    mkdir(frameDir);
end

set(fig, 'Renderer', 'opengl');     % painters cannot render surf/lighting
try
    for k = 1:nFrames
        frameFcn(k);
        drawnow limitrate;
        img = grab_frame(fig, C.videoRes);
        if useVW
            writeVideo(vw, img);
        else
            imwrite(img, fullfile(frameDir, sprintf('frame_%05d.png', k)));
        end
        if mod(k, 120) == 0
            fprintf('    %s: %d/%d frames\n', clipName, k, nFrames);
        end
    end
catch ME
    if useVW && ~isempty(vw), close(vw); end
    close(fig);
    R.status = 'failed';
    R.note = getReport(ME, 'basic');
    R.elapsed = toc;
    fprintf('  [fail] clip %s: %s\n', clipName, ME.message);
    return
end

if useVW
    close(vw);
    R.status = 'mp4';
    R.file = outFile;
else
    F = find_ffmpeg();
    if F.found
        inPat = to_shell_path(fullfile(frameDir, 'frame_%05d.png'), F.mode);
        outP  = to_shell_path(outFile, F.mode);
        cmd = sprintf(['%s -y -loglevel error -framerate %d -i "%s" ' ...
                       '-c:v libx264 -pix_fmt yuv420p -crf 18 ' ...
                       '-movflags +faststart "%s"'], ...
                       F.prefix, C.videoFps, inPat, outP);
        st = sys_quiet(cmd);
        if st == 0
            R.status = 'ffmpeg';
            R.file = outFile;
        else
            R.status = 'frames';
            R.file = frameDir;
            R.note = [R.note ' | ffmpeg returned nonzero, PNG sequence kept'];
        end
    else
        R.status = 'frames';
        R.file = frameDir;
        R.note = [R.note ' | no ffmpeg, PNG sequence kept'];
    end
end

close(fig);
R.elapsed = toc;
fprintf('  clip %-16s %5.1f s of video, %4d frames, %s, %.0f s render\n', ...
        clipName, R.seconds, nFrames, R.status, R.elapsed);
end
