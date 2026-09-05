%RUN_ALL  Entry point for the whole build.
%
%   >> run_all                        physics, figures and audit, ~90 s
%   >> build_all('--video')           the same plus the eight clips and the reel
%   >> build_all('--verify')          every tolerance and solver budget tightened
%
%   Video is opt-in: the physics takes about a minute and a half, the render
%   takes ten. See build_all.m for the orchestration and
%   results/BUILD_REPORT.md for what actually happened.

metrics = build_all();
