# Lunar Return Rendezvous

A crew lifts off from the Moon. Their ascent stage reaches a 100 km circular orbit with the
dispersion that a single-string engine and a shifting centre of mass always leave behind. Their
mothership is 300 km higher and ten degrees ahead. Nobody is coming to help.

This repository is my end-to-end MATLAB simulation of what happens next: the phasing wait, the
Hohmann climb, the proximity operations that buy back the injection error, the perturbations that
pull the meeting point apart, a three-body re-check of the whole manoeuvre, and the five-joint arm
that finally grabs the vehicle. Everything is written from scratch — `ode45` and `fminsearch` are
the only solvers used, and no MathWorks toolbox beyond base MATLAB is required.

## Watch

[![showreel](results/figures/fig02_hohmann_geometry.png)](results/video/showreel.mp4)

**[▶ results/video/showreel.mp4](results/video/showreel.mp4)** — 85 seconds, silent, 1920×1080.
A square 1080×1080 cut for social feeds sits next to it as `showreel_square.mp4`, and the individual
clips are in `results/video/clips/`.

| | | |
|---|---|---|
| ![hohmann](results/figures/02_hohmann.gif) | ![proximity](results/figures/03_proximity.gif) | ![arm](results/figures/06_arm.gif) |
| Phasing and Hohmann climb | 50 m hold, then V-bar docking | 5R berthing arm |

---

## The mission

| | |
|---|---|
| Chaser | lunar module, 100 km circular equatorial orbit |
| Target | mothership, 400 km circular equatorial orbit, 10° ahead at t = 0 |
| Frame | Moon-centered inertial, +z lunar north, planar motion |
| Total Δv, orbital phase | **118.80 m/s** |
| Total Δv, proximity phase | **1.28 m/s** |
| Wall-clock mission | **10.54 h** (9.44 h of it waiting for the phasing window) |

---

## Physics modules

**1 · Orbital transfer** — Tangential Hohmann transfer between the two circular orbits, plus the
phasing analysis that decides when to light the engine. The required lead angle at ignition is
18.61°, the mothership only leads by 10°, so the window has just been missed and the chaser waits
**9.44 hours** for a full relative revolution. The whole timeline is then propagated twice, once
with `ode45` at `RelTol = AbsTol = 1e-12` and once in closed form through Kepler's equation. They
agree to **1.9 × 10⁻⁴ m** over ten hours of flight, which is the number that makes every figure
downstream trustworthy.

**2 · Proximity operations** — A random injection error (529 m, 0.88 m/s from seed 42) is propagated
with the Hill–Clohessy–Wiltshire state transition matrix. Left alone it becomes a **21 km** drift in
three orbits. A two-impulse transfer buys the 50 m V-bar hold for **1.12 m/s**, and a five-leg forced
straight-line approach walks the vehicle into the docking port for another **0.16 m/s**. The linear
model is then checked against the exact nonlinear relative equations of motion: they part company by
about 100 m after three orbits at kilometre range, and by well under a millimetre at the 50 m hold,
where ρ/R₂ ≈ 2 × 10⁻⁵.

**3 · Perturbations** — The same manoeuvre plan is flown against a Cowell model with lunar J2 and the
Earth as a third body, deliberately **without retargeting**. The Keplerian design misses by
**15.1 km**; the Earth's own contribution to that miss is **116 m**. Sized as an impulse, removing the
error costs roughly n₂·|miss| ≈ **10.7 m/s**, which is the mid-course correction budget a real flight
plan would carry.

**4 · Berthing manipulator** — A five-revolute arm on a free-flying base: Grübler mobility, cylinder
inertias, homogeneous-transform forward kinematics, and the 36 × 11 twist-propagation matrix **N**
that maps base and joint velocities to every body twist. Kineto-static duality τ = Nᵀw then gives
the joint torques and the base reaction for three postures under two berthing wrenches. The folded
posture loads the shoulder to **396 N·m** under a 100 N axial push; the same load in the extended
posture costs 80 N·m.

**5 · CR3BP verification** — The transfer is re-converged by single shooting on
[δvₓ, δv_y, TOF] in the Earth–Moon synodic frame with μ = 0.01215. The rendezvous closes to
**under a metre**, and the correction to the two-body design is **8.8 mm/s** of Δv and **0.9 s** of
time of flight. That is the honest answer to "does the Earth matter here?": not much, and now it is
quantified rather than assumed.

**6 · Inverse kinematics** — A 5R arm cannot serve all six task degrees of freedom, so the solver
says so out loud: weighted damped least squares with W = diag(1,1,1,1,1,0.01) spends the redundancy
on position and accepts an attitude residual. It reaches a reachable target to **0.99 mm in 18
iterations**, and the capture is flown as a rest-to-rest cubic over 30 s.

---

## How to run

```matlab
>> run_all          % or: build_all
```

Roughly ten minutes on a laptop: about one minute of physics and the rest rendering video. From a
shell:

```bash
matlab -batch "run_all"
```

A note on the entry point. MATLAB identifiers may not start with a digit, so a file named
`00_main.m` cannot be executed — not as `00_main`, and not through `run('00_main.m')` either; both
fail with *Invalid text character* before a line is parsed. `00_main.m` is kept as the documented
entry point and says exactly this in its header; the orchestration lives in `build_all.m`, and
`run_all` is the one-word alias to type.

Headless Linux needs a framebuffer for the video stage:

```bash
xvfb-run -a matlab -batch "run_all"
```

Figures only, no rendering — edit `config/mission_constants.m` and set `C.makeVideo = false`.

Unit tests, under a second:

```matlab
>> run_unit_tests
```

If MATLAB cannot reach `ffmpeg`, the clips are still written and the reel can be assembled by hand:

```bash
./tools/concat_showreel.sh
```

Outputs land in `results/`: 20 PNG figures, eight MP4 clips (the seven that make up the reel plus a
supplementary inverse-kinematics telemetry clip), the reel itself, `metrics.mat`, `metrics.json`, and
`BUILD_REPORT.md` — which is the file to read first, because it records what passed, what failed and
how long it took.

---

## Results gallery

| | |
|---|---|
| ![fig02](results/figures/fig02_hohmann_geometry.png) | ![fig04](results/figures/fig04_position_errors.png) |
| Hohmann geometry at t = 0 and at ignition | Numerical minus analytical, over ten hours |
| ![fig06](results/figures/fig06_free_drift_3d.png) | ![fig08](results/figures/fig08_forced_vbar_docking.png) |
| Free drift of the injection error | Forced V-bar approach to the port |
| ![fig11](results/figures/fig11_j2_vs_kepler.png) | ![fig13](results/figures/fig13_coe_histories.png) |
| J2 against the Keplerian design | Classical elements under J2 + third body |
| ![fig14](results/figures/fig14_fkine_verification.png) | ![fig15](results/figures/fig15_three_postures.png) |
| Forward kinematics verification pose | Three postures under the berthing load |
| ![fig16](results/figures/fig16_cr3bp_transfer.png) | ![fig17](results/figures/fig17_joint_trajectory.png) |
| CR3BP transfer in the synodic frame | Rest-to-rest cubic joint trajectory |

The full set, `fig01` through `fig20`, is in `results/figures/`.

---

## Repository layout

```
build_all.m               orchestrator: physics, figures, video, reports
run_all.m                 alias, the thing to type
00_main.m                 documented entry point (see the note above)
config/mission_constants.m  every physical constant, in one struct
lib/astro/                two-body, J2, third body, Kepler, elements, Hohmann, phasing
lib/relative/             HCW state transition matrix, targeting, nonlinear relative EOM
lib/cr3bp/                synodic equations of motion, frame conversions, shooting
lib/robot/                kinematics, twist propagation, wrenches, WDLS, trajectories
parts/                    the six studies, each one figure-producing script
viz/                      dark theme, scene primitives, HUD, encoder, seven animations
tests/                    seven acceptance tests, sub-second
tools/concat_showreel.sh  standalone reel assembly
docs/                     physics notes, lander survey, launch posts
results/                  figures, video, metrics, build report
```

Every part saves its time histories to `results/traj_partN.mat`, and the animations load those
files and nothing else. A failed encoder therefore cannot invalidate the science, and re-cutting the
video never re-runs an integrator.

---

## Limitations

I would rather list these than let a reader discover them.

- **Equatorial and coplanar only.** No inclination change, no relative RAAN, so the out-of-plane
  budget that dominates real rendezvous planning never appears.
- **Gravity stops at J2.** No mascons, no higher-order lunar field. Low lunar orbits are genuinely
  unstable under the real field on timescales of weeks; nothing here runs that long, but the
  frozen-orbit design that a real mission would use is out of scope.
- **No solar radiation pressure integration.** It is estimated at ~10⁻⁷ m/s² in `docs/physics_notes.md`
  and left out; the flag exists but the cannonball model is not wired in.
- **Impulsive burns.** Finite-burn losses, throttle profiles and attitude slews are not modelled.
- **The arm is kinematic and static.** Five degrees of freedom, a base held fixed by assumption, no
  joint flexibility, no free-floating momentum coupling, no contact dynamics. The LVLH frame is
  treated as inertial during berthing.
- **One random draw.** The injection error is a single realisation of seed 42, not a Monte Carlo.
  The Δv figures for the proximity phase are therefore one sample, not a distribution.

---

## References

Public textbooks and papers only.

- H. D. Curtis, *Orbital Mechanics for Engineering Students*
- D. A. Vallado, *Fundamentals of Astrodynamics and Applications*
- W. Fehse, *Automated Rendezvous and Docking of Spacecraft*
- W. H. Clohessy and R. S. Wiltshire, "Terminal Guidance System for Satellite Rendezvous",
  *Journal of the Aerospace Sciences*, 1960
- B. Siciliano, L. Sciavicco, L. Villani, G. Oriolo, *Robotics: Modelling, Planning and Control*
- R. H. Battin, *An Introduction to the Mathematics and Methods of Astrodynamics*
- V. Szebehely, *Theory of Orbits: The Restricted Problem of Three Bodies*

## License

MIT — see [LICENSE](LICENSE).
