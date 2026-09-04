function [status, out] = sys_quiet(cmd)
%SYS_QUIET  Run a shell command without the Windows UNC working-directory noise.
%
%   [status, out] = SYS_QUIET(cmd)
%
%   On Windows, system() launches cmd.exe with the MATLAB working directory.
%   When the repository lives on a UNC path - which it does whenever it is
%   checked out inside WSL and driven from a Windows MATLAB - cmd.exe prints a
%   three-line complaint before running anything. The command still works, but
%   the build log fills with warnings that look like failures.
%
%   Hopping to the temp directory first removes the noise. Every path this
%   repository passes to a shell is absolute, so nothing depends on the cwd.

here = pwd;
c = onCleanup(@() cd(here));
try
    cd(tempdir);
catch
    % If tempdir is unavailable, run from wherever we are; noisy but working.
end
[status, out] = system(cmd);
end
