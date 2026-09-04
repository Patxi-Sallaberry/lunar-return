%00_MAIN  Documented entry point for the lunar-return build.
%
%   IMPORTANT: this file cannot be executed under its own name. MATLAB
%   identifiers may not start with a digit, so both
%
%       >> 00_main
%       >> run('00_main.m')
%
%   fail with "Invalid text character" before a single line is parsed. That is
%   a language rule, not a bug in this repository.
%
%   Use either of these instead - they do exactly the same thing:
%
%       >> run_all
%       >> build_all
%
%   or from a shell
%
%       $ matlab -batch "run_all"
%       $ xvfb-run -a matlab -batch "run_all"     % headless Linux
%
%   The orchestration itself lives in build_all.m: parts 1 to 6, the
%   documentation figure, the seven video clips, the showreel, metrics.mat,
%   metrics.json and results/BUILD_REPORT.md.

build_all();
