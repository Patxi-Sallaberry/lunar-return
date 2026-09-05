function write_metrics_json(path, m, root)
%WRITE_METRICS_JSON  Emit a metrics struct as JSON, without any toolbox.
%   WRITE_METRICS_JSON(path, m)
%   WRITE_METRICS_JSON(path, m, root)  makes absolute paths under `root`
%   repo-relative.
%
%   Scalars, logicals, short numeric vectors and strings are written; anything
%   larger or of another class is skipped, because metrics.json is meant to be
%   read by a human and by a CI job, not to serialise the whole workspace.
%
%   String handling is the part that matters. Pass 1 wrote absolute Windows and
%   UNC paths straight into the file, so values such as
%   "\\wsl.localhost\ubuntu\root\..." contained bare backslashes. JSON reads
%   `\u` as the start of a unicode escape, so the file was silently
%   unparseable by every JSON reader while still looking fine to a human. Paths
%   under the repository root are therefore rewritten as repo-relative POSIX
%   paths, and any remaining backslash is escaped properly.

if nargin < 3 || isempty(root), root = ''; end

f = fieldnames(m);
fid = fopen(path, 'w');
if fid < 0
    error('write_metrics_json:open', 'Cannot write %s', path);
end
closer = onCleanup(@() fclose(fid));

fprintf(fid, '{\n');
first = true;
for k = 1:numel(f)
    v = m.(f{k});

    if ischar(v) || isstring(v)
        str = sprintf('"%s"', json_string(char(v), root));
    elseif islogical(v) && isscalar(v)
        if v, str = 'true'; else, str = 'false'; end
    elseif isnumeric(v) && isscalar(v)
        if isfinite(v), str = sprintf('%.10g', v); else, str = 'null'; end
    elseif isnumeric(v) && isvector(v) && numel(v) <= 12
        str = ['[' strtrim(sprintf('%.10g, ', v))];
        str = [str(1:end-1) ']'];
    else
        continue
    end

    if ~first, fprintf(fid, ',\n'); end
    fprintf(fid, '  "%s": %s', f{k}, str);
    first = false;
end
fprintf(fid, '\n}\n');
end

% ------------------------------------------------------------------ helpers --
function s = json_string(s, root)
if ~isempty(root) && startsWith(s, root)
    s = strrep(s(numel(root)+2:end), '\', '/');   % repo-relative, POSIX
end
s = strrep(s, '\', '\\');
s = strrep(s, '"', '\"');
s = strrep(s, sprintf('\n'), '\n');
s = strrep(s, sprintf('\t'), '\t');
end
