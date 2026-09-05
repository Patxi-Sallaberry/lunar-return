function metrics = build_all()
%BUILD_ALL  Run the entire lunar-return simulation and build the media package.
%
%   metrics = BUILD_ALL()
%
%   This is the orchestrator. `run_all` and `00_main` are one-line aliases;
%   the real work lives here because MATLAB identifiers cannot start with a
%   digit, so a file literally named 00_main.m can never be executed by name
%   or through run(). Keeping the logic in a legally-named function makes the
%   entry point work from the command line, from `matlab -batch`, and from a
%   script, all at once.
%
%   Unattended by construction: no input(), no pause, no visible figure, no
%   prompt. Every part is wrapped in try/catch, writes its own trajectory
%   MAT-file, and can fail without taking the build down. What survived is
%   recorded in results/BUILD_REPORT.md, which is the file to read first.

clc;
close all force;

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, 'lib', 'util'));     % repo_genpath lives here
addpath(repo_genpath(here));

C = mission_constants();
rng(C.rngSeed);

for d = {C.resDir, C.figDir, C.vidDir, C.clipDir, C.frameDir}
    if ~exist(d{1}, 'dir'), mkdir(d{1}); end
end
old = dir(fullfile(C.resDir, 'FAIL_*.txt'));
for k = 1:numel(old)
    delete(fullfile(C.resDir, old(k).name));
end

tStart = tic;
metrics = struct();
report  = {};

fprintf('\n');
fprintf('##############################################################\n');
fprintf('#  LUNAR RETURN RENDEZVOUS  -  full build\n');
fprintf('#  MATLAB %s on %s\n', version('-release'), computer);
fprintf('#  video %d   fps %d   resolution %dx%d\n', ...
        C.makeVideo, C.videoFps, C.videoRes(1), C.videoRes(2));
fprintf('##############################################################\n');

% ============================================================== PHYSICS =====
parts = { 'part1_orbital_transfer',    'Part 1  orbital transfer'
          'part2_proximity',           'Part 2  proximity operations'
          'part3_perturbations',       'Part 3  perturbations'
          'part4_manipulator',         'Part 4  manipulator statics'
          'part5_cr3bp',               'Part 5  CR3BP transfer'
          'part6_inverse_kinematics',  'Part 6  inverse kinematics' };

for p = 1:size(parts,1)
    try
        M = feval(parts{p,1}, C);
        metrics = merge_metrics(metrics, M, p);
        report{end+1} = sprintf('| %-32s | PASS |', parts{p,2}); %#ok<AGROW>
    catch ME
        report{end+1} = sprintf('| %-32s | FAIL |', parts{p,2}); %#ok<AGROW>
        fid = fopen(fullfile(C.resDir, sprintf('FAIL_part%d.txt', p)), 'w');
        fprintf(fid, '%s\n', getReport(ME, 'extended', 'hyperlinks', 'off'));
        fclose(fid);
        fprintf('\n[FAIL] %s: %s\n       see results/FAIL_part%d.txt\n', ...
                parts{p,2}, ME.message, p);
    end
end

% Documentation figure, independent of every part.
try
    make_lander_schematic(C);
    report{end+1} = sprintf('| %-32s | PASS |', 'fig18 lander schematic');
catch ME
    report{end+1} = sprintf('| %-32s | FAIL |', 'fig18 lander schematic');
    fprintf('[warn] lander schematic failed: %s\n', ME.message);
end

% =============================================================== VIDEO ======
clips = struct('name', {}, 'status', {}, 'seconds', {});
ffm = find_ffmpeg();

if C.makeVideo
    fprintf('\n===== VIDEO ============================================\n');
    anims = { 'anim_title',              '',                '01_title'
              'anim_part1_hohmann',      'traj_part1.mat',  '02_hohmann'
              'anim_part2_proximity',    'traj_part2.mat',  '03_proximity'
              'anim_part3_perturbations','traj_part3.mat',  '04_perturbations'
              'anim_part5_cr3bp',        'traj_part5.mat',  '05_cr3bp'
              'anim_part4_arm',          'traj_part6.mat',  '06_arm'
              'anim_part6_ik',           'traj_part6.mat',  '06b_ik_telemetry' };

    for a = 1:size(anims,1)
        needed = anims{a,2};
        if ~isempty(needed) && ~exist(fullfile(C.resDir, needed), 'file')
            fprintf('  skip %s: %s missing\n', anims{a,3}, needed);
            report{end+1} = sprintf('| %-32s | SKIP |', ['video ' anims{a,3}]); %#ok<AGROW>
            continue
        end
        try
            Rc = feval(anims{a,1}, C);
            clips(end+1) = struct('name', Rc.name, 'status', Rc.status, ...
                                  'seconds', Rc.seconds); %#ok<AGROW>
            report{end+1} = sprintf('| %-32s | %s |', ['video ' anims{a,3}], ...
                                    upper(pass_of(Rc.status))); %#ok<AGROW>
        catch ME
            report{end+1} = sprintf('| %-32s | FAIL |', ['video ' anims{a,3}]); %#ok<AGROW>
            fprintf('  [fail] %s: %s\n', anims{a,3}, ME.message);
        end
        close all force
    end

    % End card last: it reads the metrics this run produced.
    try
        Rc = anim_endcard(C, metrics);
        clips(end+1) = struct('name', Rc.name, 'status', Rc.status, 'seconds', Rc.seconds);
        report{end+1} = sprintf('| %-32s | %s |', 'video 07_endcard', upper(pass_of(Rc.status)));
    catch ME
        report{end+1} = sprintf('| %-32s | FAIL |', 'video 07_endcard');
        fprintf('  [fail] 07_endcard: %s\n', ME.message);
    end
    close all force

    try
        Rs = build_showreel(C);
        report{end+1} = sprintf('| %-32s | %s |', 'showreel.mp4', passfail(Rs.reel));
        report{end+1} = sprintf('| %-32s | %s |', 'showreel_square.mp4', passfail(Rs.square));
    catch ME
        report{end+1} = sprintf('| %-32s | FAIL |', 'showreel.mp4');
        fprintf('  [fail] showreel: %s\n', ME.message);
    end
else
    fprintf('\n  C.makeVideo is false: figures only.\n');
end

% ============================================================== OUTPUTS =====
figs = dir(fullfile(C.figDir, '*.png'));
metrics.nFigures = numel(figs);
metrics.nClips = numel(clips);
if isempty(clips)
    metrics.reelSeconds = 0;
    metrics.showreelSeconds = 0;
else
    metrics.reelSeconds = sum([clips.seconds]);
    % The showreel is the seven numbered clips only; 06b is supplementary.
    inReel = ~cellfun(@isempty, regexp({clips.name}, '^0[1-7]_', 'once'));
    metrics.showreelSeconds = sum([clips(inReel).seconds]);
end
metrics.elapsedSeconds = toc(tStart);

save(fullfile(C.resDir, 'metrics.mat'), 'metrics');
write_metrics_json(fullfile(C.resDir, 'metrics.json'), metrics, C.root);
write_build_report(C, report, clips, ffm, metrics);

% ================================================================ AUDIT =====
% Run last, so it audits the metrics this build just produced rather than a
% stale file. It never throws: a broken audit must not fail the build, it must
% report that it is broken.
if ~C.skipAudit
    fprintf('\n');
    try
        auditOK = audit_reference(C);
        if auditOK
            fprintf('  Audit: no FAIL. See results/AUDIT_REPORT.md\n');
        else
            fprintf('  Audit: at least one FAIL. See results/AUDIT_REPORT.md\n');
        end
        metrics.auditPassed = auditOK;
    catch ME
        fprintf('  [warn] audit could not run: %s\n', ME.message);
        metrics.auditPassed = false;
    end
    save(fullfile(C.resDir, 'metrics.mat'), 'metrics');
    write_metrics_json(fullfile(C.resDir, 'metrics.json'), metrics, C.root);
end

% =============================================================== BANNER =====
fprintf('\n');
fprintf('========== LUNAR RETURN SIMULATION COMPLETE ==========\n');
fprintf('Hohmann dV tot     = %8.2f m/s\n',  getd(metrics,'dVtot_ms'));
fprintf('Wait + TOF         = %8.2f h\n',    getd(metrics,'t_mission_h'));
fprintf('J2 miss            = %8.2f km\n',   getd(metrics,'miss_J2_km'));
fprintf('J2+3B miss         = %8.2f km\n',   getd(metrics,'miss_J2_3B_km'));
fprintf('Hold dV            = %8.3f m/s\n',  getd(metrics,'dV_hold_ms'));
fprintf('Dock dV            = %8.3f m/s\n',  getd(metrics,'dV_dock_ms'));
fprintf('CR3BP extra dV     = %8.2f mm/s\n', getd(metrics,'dV_extra_mms'));
fprintf('IK pos residual    = %8.2f mm\n',   getd(metrics,'ik_res_mm'));
fprintf('Figures written    = %8d\n',        metrics.nFigures);
fprintf('Showreel           = %8.1f s (%d clips rendered in total)\n', ...
        metrics.showreelSeconds, numel(clips));
fprintf('Elapsed            = %8s\n',        mmss(metrics.elapsedSeconds));
fprintf('======================================================\n');
fprintf('Report: results/BUILD_REPORT.md\n\n');
end

% ============================================================== HELPERS =====
function out = merge_metrics(out, M, partNo)
%MERGE_METRICS  Flatten a part's metrics into one struct, renaming collisions.
f = fieldnames(M);
for k = 1:numel(f)
    v = M.(f{k});
    if ~(isnumeric(v) || ischar(v) || islogical(v) || isstring(v))
        continue
    end
    name = f{k};
    if isfield(out, name)
        name = sprintf('p%d_%s', partNo, f{k});
    end
    out.(name) = v;
end
end

function s = pass_of(st)
if any(strcmp(st, {'mp4','ffmpeg','frames'})), s = 'pass'; else, s = 'fail'; end
end

function s = passfail(tf)
if tf, s = 'PASS'; else, s = 'FAIL'; end
end

function v = getd(m, f)
if isfield(m, f) && isnumeric(m.(f)) && isscalar(m.(f)), v = m.(f); else, v = NaN; end
end

function s = mmss(t)
s = sprintf('%02d:%02d', floor(t/60), round(mod(t,60)));
end

function write_build_report(C, report, clips, ffm, m)
fid = fopen(fullfile(C.resDir, 'BUILD_REPORT.md'), 'w');
fprintf(fid, '# Build report\n\n');
fprintf(fid, 'This is the overnight summary. Read it before anything else.\n\n');
fprintf(fid, '- date: %s\n', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')));
fprintf(fid, '- MATLAB: %s on %s\n', version('-release'), computer);
fprintf(fid, '- ffmpeg: %s\n', ffm.mode);
fprintf(fid, '- elapsed: %s\n', mmss(m.elapsedSeconds));
fprintf(fid, '- figures: %d PNG\n', m.nFigures);
fprintf(fid, '- clips: %.1f s across %d files; the showreel concatenates the seven numbered ones\n\n', ...
        m.reelSeconds, numel(clips));

fprintf(fid, '| stage | result |\n|---|---|\n');
for k = 1:numel(report)
    fprintf(fid, '%s\n', report{k});
end

fprintf(fid, '\n## Clips\n\n| clip | seconds | encoder |\n|---|---|---|\n');
for k = 1:numel(clips)
    fprintf(fid, '| %s | %.1f | %s |\n', clips(k).name, clips(k).seconds, clips(k).status);
end

fprintf(fid, '\n## Headline numbers\n\n');
fprintf(fid, '| quantity | value |\n|---|---|\n');
rows = { 'Hohmann dV total [m/s]',      'dVtot_ms'
         'Phasing wait [h]',            't_wait_h'
         'Mission duration [h]',        't_mission_h'
         'Num-vs-analytic error [m]',   'errLM_max_m'
         'Injection error [m]',         'dr0_norm_m'
         'Hold acquisition dV [m/s]',   'dV_hold_ms'
         'Docking dV [m/s]',            'dV_dock_ms'
         'J2 miss [km]',                'miss_J2_km'
         'J2 + 3B miss [km]',           'miss_J2_3B_km'
         'Third-body only [m]',         'miss_3Bonly_m'
         'Mid-course correction [m/s]', 'dV_mcc_ms'
         'CR3BP miss [m]',              'miss_m'
         'CR3BP extra dV [mm/s]',       'dV_extra_mms'
         'Arm reach [m]',               'reach_m'
         'Peak joint torque [N m]',     'tau_max_Nm'
         'IK residual [mm]',            'ik_res_mm'
         'IK iterations',               'ik_iters' };
for k = 1:size(rows,1)
    v = getd(m, rows{k,2});
    if isnan(v)
        fprintf(fid, '| %s | n/a |\n', rows{k,1});
    else
        fprintf(fid, '| %s | %.4g |\n', rows{k,1}, v);
    end
end

failed = dir(fullfile(C.resDir, 'FAIL_*.txt'));
if isempty(failed)
    fprintf(fid, '\nNo part failed. Stack traces, if there had been any, would be in results/FAIL_partN.txt.\n');
else
    fprintf(fid, '\n## Failures\n\n');
    for k = 1:numel(failed)
        fprintf(fid, '- `%s`\n', failed(k).name);
    end
end
fclose(fid);
end
