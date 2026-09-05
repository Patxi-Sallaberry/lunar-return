function C = mission_constants()
%MISSION_CONSTANTS  Single source of truth for the lunar-return simulation.
%
%   C = MISSION_CONSTANTS() returns a struct holding every physical constant,
%   mission geometry parameter, numerical tolerance and rendering option used
%   by the repository. Nothing else in the code base is allowed to hard-code a
%   physical value: if a number matters, it lives here.
%
%   Units: astrodynamics is done in km and km/s (mu in km^3/s^2). Proximity
%   operations and robotics are done in m, m/s, rad. Conversions are always
%   explicit and local to the function that needs them.
%
%   Frame: Moon-centered inertial (MCI), equatorial, +z = lunar north, motion
%   counter-clockwise in the xy-plane.

% ---------------------------------------------------------------- gravity ---
C.muMoon   = 4902.8;        % [km^3/s^2] lunar gravitational parameter
C.RMoon    = 1737.4;        % [km]       lunar mean radius
C.J2Moon   = 2.033e-4;      % [-]        lunar oblateness coefficient
C.muEarth  = 3.986e5;       % [km^3/s^2] Earth gravitational parameter
C.dEM      = 384400;        % [km]       mean Earth-Moon distance

% -------------------------------------------------------------- geometry ----
C.h1       = 100;                       % [km] LM parking altitude
C.h2       = 400;                       % [km] mothership altitude
C.R1       = C.RMoon + C.h1;            % [km] = 1837.4
C.R2       = C.RMoon + C.h2;            % [km] = 2137.4
C.phi0     = deg2rad(10);               % [rad] MS lead angle over LM at t = 0

% Mean motions of the two circular orbits (used everywhere downstream).
C.n1       = sqrt(C.muMoon / C.R1^3);   % [rad/s]
C.n2       = sqrt(C.muMoon / C.R2^3);   % [rad/s]
C.T1       = 2*pi / C.n1;               % [s]
C.T2       = 2*pi / C.n2;               % [s] mothership orbital period

% ---------------------------------------------------- proximity operations --
% LVLH of the mothership. NON-STANDARD axis convention, kept throughout:
%   x = along-track (V-bar), y = cross-track, z = radial (R-bar, outward).
C.r_hold   = [50; 0; 0];                % [m] V-bar hold point
C.v_hold   = [0; 0; 0];                 % [m/s]
C.dt_tr    = 0.3 * C.T2;                % [s] two-impulse transfer duration
C.N_legs   = 5;                         % forced V-bar docking legs
C.T_dock   = 1000;                      % [s] total forced docking time
C.nDriftOrbits = 3;                     % free-drift horizon, MS periods

% Injection-error draw bounds (Part 2). The seed is the reproducibility
% mechanism; the realisation itself is never frozen to a magic number.
C.errPosRange = [500 1000];             % [m]
C.errVelRange = [0.1 1.0];              % [m/s]

% ------------------------------------------------------------------ CR3BP ---
C.muCR3BP  = 0.01215;                                   % [-] mass parameter
C.LU       = C.dEM;                                     % [km] length unit
C.TU       = sqrt(C.LU^3 / (C.muEarth + C.muMoon));     % [s]  time unit
C.VU       = C.LU / C.TU;                               % [km/s] velocity unit
C.nEM      = sqrt((C.muMoon + C.muEarth) / C.dEM^3);    % [rad/s] = 1/TU

% -------------------------------------------------------------- robotics ----
C.armL     = [0.6 3.2 2.8 0.6 0.5];     % [m]  link lengths
C.armM     = [30 100 85 20 15];         % [kg] link masses
C.armR     = 0.15;                      % [m]  cylinder radius
% Joint axes expressed in the local joint frame, before the joint rotation.
C.armAxes  = [0 0 1; 0 1 0; 0 1 0; 0 1 0; 1 0 0].';     % 3x5, column i = e_i
% p_mount = 0 so the forward-kinematics acceptance pose reproduces the
% reference end-effector position [5.305; 0; 4.558] m exactly. The mothership
% body is drawn slightly behind the base so the arm still looks bolted on.
C.p_mount  = [0; 0; 0];                 % [m]
C.msCube   = 2.0;                       % [m] mothership bus edge length
C.msCubeCenter = [-1.2; 0; -0.4];       % [m] drawn offset, cosmetic only

C.wrench1  = struct('F', [0; 0; -100], 'M', [0; 0; 0]);        % N, N*m (local)
C.wrench2  = struct('F', [15; -10; -80], 'M', [12; 8; -5]);    % N, N*m (local)

C.q_ext    = deg2rad([  0  10  -5  -5   0]).';   % nearly extended posture
C.q_bent   = deg2rad([  0  70 -90 -20   0]).';   % folded posture
C.q_arb    = deg2rad([ 40  35 -20  50  25]).';   % general spatial posture

C.ik_lambda = 0.05;                     % WDLS damping
C.ik_alpha  = 0.4;                      % WDLS step gain
C.ik_W      = diag([1 1 1 1 1 0.01]);   % de-weights the DOF a 5R cannot serve
C.ik_maxIter = 200;
C.ik_tolPos  = 1e-3;                    % [m]
C.ik_tf      = 30;                      % [s] rest-to-rest cubic duration

% -------------------------------------------------------------- numerics ----
C.rngSeed  = 42;
C.odeTight = odeset('RelTol', 1e-12, 'AbsTol', 1e-12);  % Part 1 validation
C.odeWork  = odeset('RelTol', 1e-10, 'AbsTol', 1e-10);  % Parts 3 and 5

% --------------------------------------------------------------- rendering --
C.makeVideo   = true;
C.skipAudit   = false;          % tests/audit_reference.m runs at the end of a build
C.enableSRP   = false;          % cannonball SRP: estimated in docs, not integrated
C.enableC22   = false;          % lunar ellipticity: out of scope, see the report
C.videoFps    = 30;
C.videoCRF    = 17;             % x264 quality for the delivery encode
C.videoRes    = [1920 1080];
C.previewFps  = 15;
C.maxFramesPerClip = 900;
C.figDPI      = 200;

% Project identity. Kept here rather than baked into the end card so that a
% fork only has to change one line to re-render the video with its own URL.
C.repoURL     = 'github.com/Patxi-Sallaberry/lunar-return-rendezvous';

% Repository root, resolved from this file so nothing depends on the caller's
% working directory.
C.root        = fileparts(fileparts(mfilename('fullpath')));
C.figDir      = fullfile(C.root, 'results', 'figures');
C.resDir      = fullfile(C.root, 'results');
C.vidDir      = fullfile(C.root, 'results', 'video');
C.clipDir     = fullfile(C.vidDir, 'clips');
C.frameDir    = fullfile(C.vidDir, 'frames');
end
