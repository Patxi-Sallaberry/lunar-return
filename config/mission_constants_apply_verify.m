function C = mission_constants_apply_verify(C)
%MISSION_CONSTANTS_APPLY_VERIFY  Switch a constants struct to verification mode.
%
%   C = MISSION_CONSTANTS_APPLY_VERIFY(C)
%
%   Production and verification differ only in how hard the numerics are
%   pushed, never in the model. Verification exists so that a reviewer can
%   confirm the production answer is not a tolerance artefact; measured, the
%   Kepler residual is 0.19 mm in both modes, which is the point.

C.verify    = true;
C.odeTight  = odeset('RelTol', 1e-12, 'AbsTol', 1e-14);
C.odeWork   = odeset('RelTol', 1e-12, 'AbsTol', 1e-14);
C.nKepler   = 4000;
C.maxEvalCR = 200;
C.maxEvalMC = 200;
end
