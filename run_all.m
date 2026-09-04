%RUN_ALL  Entry point for the whole build.
%
%   >> run_all
%
%   Runs parts 1 to 6, writes every figure, renders the seven video clips and
%   the showreel, and leaves `metrics` in the workspace. See build_all.m for
%   the orchestration and results/BUILD_REPORT.md for what actually happened.

metrics = build_all();
