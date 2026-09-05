function n = export_report_figures(C)
%EXPORT_REPORT_FIGURES  Re-render the science figures in the academic theme.
%
%   n = EXPORT_REPORT_FIGURES(C) writes light-background, 300 dpi versions of
%   every figure into docs/report/figs/ and returns how many were produced.
%
%   The README and the video are dark; a printed report is not. Rather than
%   maintain two sets of plotting code, the parts are simply re-run with the
%   light palette selected and the output directory redirected. The physics is
%   identical - `rng(C.rngSeed)` is re-seeded inside part 2, so the injection
%   error is the same draw as the official build - only the colours change.
%
%   Video rendering is forced off here: this is a figure pass, nothing else.

figDir = fullfile(C.root, 'docs', 'report', 'figs');
if ~exist(figDir, 'dir'), mkdir(figDir); end

Cl = C;
Cl.figDir   = figDir;
Cl.makeVideo = false;
Cl.figDPI   = 300;

prev = set_style_theme('light');
restore = onCleanup(@() set_style_theme(prev));

parts = { 'part1_orbital_transfer', 'part2_proximity', 'part3_perturbations', ...
          'part4_manipulator',      'part5_cr3bp',     'part6_inverse_kinematics' };

fprintf('  exporting report figures (light theme, %d dpi)\n', Cl.figDPI);
for k = 1:numel(parts)
    try
        evalc(sprintf('%s(Cl);', parts{k}));   % suppress the part's console table
    catch ME
        fprintf('    [warn] %s: %s\n', parts{k}, ME.message);
    end
    close all force
end

try
    make_lander_schematic(Cl);
catch ME
    fprintf('    [warn] lander schematic: %s\n', ME.message);
end
close all force

n = numel(dir(fullfile(figDir, '*.png')));
fprintf('    %d figures written to docs/report/figs\n', n);
end
