function D = forced_vbar_docking(r0, v0, r_hold, Nlegs, T_dock, n)
%FORCED_VBAR_DOCKING  Straight-line V-bar approach flown as N impulsive legs.
%   D = FORCED_VBAR_DOCKING(r0, v0, r_hold, Nlegs, T_dock, n) starts from the
%   hold point (r0, v0), walks the chaser down the V-bar in Nlegs equal steps
%   of dt = T_dock/Nlegs and finishes with a braking impulse that nulls the
%   residual velocity at the port. SI units (m, m/s, rad/s).
%
%   Each waypoint is r_hold*(1 - k/Nlegs), so leg Nlegs ends exactly on the
%   docking port at the LVLH origin. This is the operational pattern used on
%   real V-bar approaches: a sequence of short targeted hops rather than a
%   continuously thrusted straight line. It keeps plume impingement away from
%   the target and bounds the closing rate between checkpoints.

r0 = r0(:); v0 = v0(:); r_hold = r_hold(:);
dt = T_dock / Nlegs;

% Conditioning guard on the block that gets inverted once per leg.
nudge = 0;
while nudge < 20
    [~, Prv] = hcw_blocks(dt, n);
    if rcond(Prv) > 1e-10
        break
    end
    dt = dt * 1.01;
    nudge = nudge + 1;
end
D.dt     = dt;
D.nudged = nudge;

M = 200;                        % samples per leg for the plotted trajectory
D.t = [];
D.x = [];
D.impulses  = zeros(3, Nlegs+1);
D.waypoints = zeros(3, Nlegs);
D.t_impulse = zeros(1, Nlegs+1);

[Prr, Prv] = hcw_blocks(dt, n);

rk = r0; vk = v0; tk = 0;
for k = 1:Nlegs
    r_tgt = r_hold * (1 - k/Nlegs);
    v_req = Prv \ (r_tgt - Prr * rk);

    D.impulses(:,k)  = v_req - vk;
    D.waypoints(:,k) = r_tgt;
    D.t_impulse(k)   = tk;

    tseg = linspace(0, dt, M);
    xseg = zeros(6, M);
    xk   = [rk; v_req];
    for j = 1:M
        xseg(:,j) = phi_hcw(tseg(j), n) * xk;
    end

    if k == 1
        D.t = tk + tseg;
        D.x = xseg;
    else
        D.t = [D.t, tk + tseg(2:end)];
        D.x = [D.x, xseg(:, 2:end)];
    end

    rk = xseg(1:3, end);
    vk = xseg(4:6, end);
    tk = tk + dt;
end

% Braking impulse at the port.
D.impulses(:, Nlegs+1) = -vk;
D.t_impulse(Nlegs+1)   = tk;
D.x(4:6, end) = D.x(4:6, end) - vk;

D.dV_each  = sqrt(sum(D.impulses.^2, 1));
D.dV_total = sum(D.dV_each);
D.r_final  = D.x(1:3, end);
D.v_final  = D.x(4:6, end);
D.err_pos  = norm(D.r_final);
D.err_vel  = norm(D.v_final);
D.T_total  = tk;
end
