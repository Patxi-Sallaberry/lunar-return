function p = repo_genpath(root)
%REPO_GENPATH  genpath() for this repository, minus the directories to skip.
%   p = REPO_GENPATH(root)
%
%   Plain genpath walks everything below root, which once the project is under
%   version control means several hundred `.git/objects/xx` directories end up
%   on the MATLAB path. That is slow, it floods the console with
%   change-notification warnings on a network path, and it makes `which` output
%   unreadable. Build artefact directories are skipped for the same reason.

skip = {[filesep '.git'], [filesep 'results' filesep 'video' filesep 'frames']};

parts = strsplit(genpath(root), pathsep);
keep  = true(size(parts));
for k = 1:numel(parts)
    if isempty(parts{k})
        keep(k) = false;
        continue
    end
    for s = 1:numel(skip)
        if contains(parts{k}, skip{s})
            keep(k) = false;
            break
        end
    end
end
p = strjoin(parts(keep), pathsep);
end
