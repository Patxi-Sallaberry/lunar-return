function ok = run_unit_tests()
%RUN_UNIT_TESTS  Every acceptance check in the repository, in one command.
%
%   >> run_unit_tests
%
%   Returns true only if all tests pass. Nothing here integrates an orbit or
%   renders a frame, so it finishes in under a second and is the right thing
%   to run before a commit.

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'lib', 'util'));
addpath(repo_genpath(root));

C = mission_constants();

suite = { @test_hohmann_numbers,      'Hohmann and phasing scalars'
          @test_hcw_stm_identity,     'HCW state transition matrix'
          @test_cr3bp_frame,          'CR3BP frame conversion'
          @test_link_inertias,        'Cylinder link inertias'
          @test_fkine_reference_pose, 'Forward kinematics reference pose'
          @test_kinetostatics,        'Kineto-static duality and equilibrium'
          @test_cubic_traj,           'Rest-to-rest cubic trajectory' };

fprintf('\n  Unit tests\n');
fprintf('  ---------------------------------------------------------------------\n');
nPass = 0;
for k = 1:size(suite,1)
    try
        [pass, msg] = suite{k,1}(C);
    catch ME
        pass = false;
        msg = ['threw: ' ME.message];
    end
    if pass
        tag = 'PASS'; nPass = nPass + 1;
    else
        tag = 'FAIL';
    end
    fprintf('  [%s] %-38s %s\n', tag, suite{k,2}, msg);
end
fprintf('  ---------------------------------------------------------------------\n');
fprintf('  %d / %d passed\n\n', nPass, size(suite,1));

ok = (nPass == size(suite,1));
end
