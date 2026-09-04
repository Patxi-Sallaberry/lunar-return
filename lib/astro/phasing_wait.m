function P = phasing_wait(n1, n2, dt_tof, phi0)
%PHASING_WAIT  Coast time on the inner orbit before the Hohmann ignition.
%   P = PHASING_WAIT(n1, n2, dt_tof, phi0) with mean motions in rad/s, the
%   Hohmann time of flight in seconds and the initial lead angle of the target
%   over the chaser in radians.
%
%   During the transfer the chaser sweeps exactly pi. The target sweeps
%   n2*dt_tof. Rendezvous therefore requires the target to lead the chaser by
%
%       dtheta_H = pi - n2*dt_tof
%
%   at ignition. The inner orbit is faster, so the *relative* angle of the
%   target as seen from the chaser decreases at n_rel = |n2 - n1|. If the
%   current lead phi0 is already smaller than the required one the window has
%   just been missed and we must wait for a full relative revolution.

P.dtheta_H = pi - n2 * dt_tof;

if P.dtheta_H >= phi0
    P.dtheta_req = 2*pi - (P.dtheta_H - phi0);
else
    P.dtheta_req = phi0 - P.dtheta_H;
end

P.n_rel     = abs(n2 - n1);
P.t_wait    = P.dtheta_req / P.n_rel;
P.t_mission = P.t_wait + dt_tof;

P.dtheta_H_deg   = rad2deg(P.dtheta_H);
P.dtheta_req_deg = rad2deg(P.dtheta_req);
P.t_wait_h       = P.t_wait / 3600;
P.t_mission_h    = P.t_mission / 3600;

% True anomaly of the chaser at ignition, measured from its t = 0 position.
P.theta_ignite = n1 * P.t_wait;
end
