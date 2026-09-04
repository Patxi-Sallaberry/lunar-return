function outPath = save_fig(fig, name, C)
%SAVE_FIG  Write a figure to results/figures as PNG, keeping the dark theme.
%   outPath = SAVE_FIG(fig, 'fig02_something', C)
%
%   exportgraphics is preferred when available; the print fallback keeps the
%   build alive on older releases and on Octave. InvertHardcopy is off on the
%   figure so the dark background survives the export.

if ~exist(C.figDir, 'dir')
    mkdir(C.figDir);
end
outPath = fullfile(C.figDir, [name '.png']);

try
    exportgraphics(fig, outPath, 'Resolution', C.figDPI, ...
                   'BackgroundColor', get(fig, 'Color'));
catch
    print(fig, '-dpng', sprintf('-r%d', C.figDPI), outPath);
end
close(fig);
end
