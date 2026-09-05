# Physics audit

Generated 2026-09-05 06:14:41 by `tests/audit_reference.m`.

**60 PASS, 1 WARN, 0 FAIL, 1 INFO.**

No failure. Every design scalar is reproduced from the raw constants in
closed form, and every order-of-magnitude result agrees with an independent
implementation of the same mission geometry.

Method: reference values are re-derived here from the raw constants, or taken
from an independent reference implementation of the same mission geometry
(100/400 km circular equatorial LLO, phi0 = 10 deg, J2 = 2.033e-4, Cowell
propagation, no retargeting). Obtained values come from `results/metrics.mat`
or from a fresh library call. Nothing is copied from a previous run banner.

| verdict | meaning |
|---|---|
| PASS | within the stated tolerance |
| WARN | same order of magnitude, divergence understood and explained |
| FAIL | a defect: units, sign, convention or a broken solve |
| INFO | recorded so a modelling choice is auditable; not scored |

A limit shown as `&le; x` is an acceptance bound, not a target: being far
below it is the desired outcome, so no relative error is quoted for those rows.


## A. Hohmann design, closed form vs literature

| quantity | unit | ref / limit | obtained | abs. err | rel. err | verdict | note |
|---|---|---|---|---|---|---|---|
| semi-major axis a | km | 1987.4 | 1987.4 | 0 | 0.00e+00 | **PASS** |  |
| eccentricity e | - | 0.0755 | 0.0754755 | 2.45e-05 | 3.25e-04 | **PASS** |  |
| circular speed vc1 | km/s | 1.6335 | 1.6335 | 4.11e-06 | 2.52e-06 | **PASS** |  |
| circular speed vc2 | km/s | 1.5145 | 1.51453 | 3.46e-05 | 2.28e-05 | **PASS** |  |
| ellipse periapsis vpe | km/s | 1.694 | 1.69403 | 2.76e-05 | 1.63e-05 | **PASS** |  |
| ellipse apoapsis vap | km/s | 1.4563 | 1.45626 | 4.17e-05 | 2.87e-05 | **PASS** |  |
| departure impulse dV1 | m/s | 60.52 | 60.5235 | 0.00353 | 5.83e-05 | **PASS** |  |
| arrival impulse dV2 | m/s | 58.28 | 58.2763 | 0.0037 | 6.35e-05 | **PASS** |  |
| total dV | m/s | 118.8 | 118.8 | 0.000171 | 1.44e-06 | **PASS** |  |
| ellipse period Tell | s | 7950.34 | 7950.34 | 0.00011 | 1.38e-08 | **PASS** |  |
| time of flight | s | 3975.17 | 3975.17 | 5.5e-05 | 1.38e-08 | **PASS** |  |
| required lead dtheta_H | deg | 18.61 | 18.6118 | 0.00182 | 9.78e-05 | **PASS** |  |
| phasing wait t_wait | s | 33988 | 33987.9 | 0.0671 | 1.97e-06 | **PASS** |  |

## B. Library vs the closed form above (machine precision expected)

| quantity | unit | ref / limit | obtained | abs. err | rel. err | verdict | note |
|---|---|---|---|---|---|---|---|
| hohmann_design dVtot | m/s | 118.8 | 118.8 | 0 | 0.00e+00 | **PASS** |  |
| hohmann_design a | km | 1987.4 | 1987.4 | 0 | 0.00e+00 | **PASS** |  |
| hohmann_design e | - | 0.0754755 | 0.0754755 | 0 | 0.00e+00 | **PASS** |  |
| hohmann_design TOF | s | 3975.17 | 3975.17 | 0 | 0.00e+00 | **PASS** |  |
| phasing_wait t_wait | s | 33987.9 | 33987.9 | 0 | 0.00e+00 | **PASS** |  |

## C. Constants of motion, per leg

| quantity | unit | ref / limit | obtained | abs. err | rel. err | verdict | note |
|---|---|---|---|---|---|---|---|
| inner circular  |h| | km^2/s | 3001.4 | 3001.4 | 0.00046 | 1.53e-07 | **PASS** |  |
| inner circular  eps | km^2/s^2 | -1.3342 | -1.33417 | 3.22e-05 | 2.41e-05 | **PASS** |  |
| transfer ellipse  |h| | km^2/s | 3112.6 | 3112.61 | 0.00639 | 2.05e-06 | **PASS** |  |
| transfer ellipse  eps | km^2/s^2 | -1.2335 | -1.23347 | 2.91e-05 | 2.36e-05 | **PASS** |  |
| outer circular  |h| | km^2/s | 3237.2 | 3237.17 | 0.0338 | 1.05e-05 | **PASS** |  |
| outer circular  eps | km^2/s^2 | -1.1469 | -1.14691 | 7.46e-06 | 6.50e-06 | **PASS** |  |
| inner circular  |h| (simulated) | km^2/s | 3001.4 | 3001.4 | 2.26e-09 | 7.52e-13 | **PASS** |  |
| transfer ellipse  |h| (simulated) | km^2/s | 3112.61 | 3112.61 | 5.16e-09 | 1.66e-12 | **PASS** |  |
| outer circular  |h| (simulated) | km^2/s | 3237.17 | 3237.17 | 5.96e-09 | 1.84e-12 | **PASS** |  |

## D. Numerical propagation vs analytical Kepler

| quantity | unit | ref / limit | obtained | abs. err | rel. err | verdict | note |
|---|---|---|---|---|---|---|---|
| max |r_num - r_ana|, LM | m | &le; 0.001 | 0.00019123 | - | - | **PASS** | ode45 at RelTol = AbsTol = 1e-12 over the full 10.5 h timeline |
| max |r_num - r_ana|, MS | m | &le; 0.001 | 0.000125833 | - | - | **PASS** |  |
| rendezvous miss, Keplerian | m | &le; 0.001 | 5.64763e-05 | - | - | **PASS** | the phasing solution is exact by construction |

## E. HCW state transition matrix and axis convention

| quantity | unit | ref / limit | obtained | abs. err | rel. err | verdict | note |
|---|---|---|---|---|---|---|---|
| |Phi(0) - I| | - | &le; 1e-12 | 0 | - | - | **PASS** |  |
| |dPhi/dt(0) - A| | - | &le; 0.0001 | 2.22045e-16 | - | - | **PASS** | pins the Coriolis signs of this frame |
| rcond(Phi_rv) at 0.3 T_MS | - | &ge; 0.0001 | 0.212827 | - | - | **PASS** | conditioning of the block every targeting solve inverts |
| |Phi(t)Phi(-t) - I| | - | &le; 1e-09 | 6.21297e-13 | - | - | **PASS** |  |
| hold |dV1| on the REFERENCE error | m/s | 1.1 | 1.07141 | 0.0286 | 2.60e-02 | **PASS** | convention arbiter |
| hold dV total on the REFERENCE error | m/s | 1.4 | 1.41932 | 0.0193 | 1.38e-02 | **PASS** | convention arbiter |
| same, mirrored convention Phi(t,-n) | m/s | 1.4 | 1.27664 | 0.123 | 8.81e-02 | **INFO** | rejected: does not reproduce the reference |
| along-track drift after 3 orbits, z0 = +100 m | m | n/a | 11309.7 | - | - | **PASS** | +x is the trailing direction, so positive = fell behind = correct |

## F. Proximity operations

| quantity | unit | ref / limit | obtained | abs. err | rel. err | verdict | note |
|---|---|---|---|---|---|---|---|
| hold dV, OUR rng(42) draw | m/s | 1.4 | 1.12287 | 0.277 | 1.98e-01 | **PASS** | different injection error than the reference draw; band 0.5-3 m/s |
| docking dV, N=5, T=1000 s | m/s | 0.1567 | 0.156733 | 3.32e-05 | 2.12e-04 | **PASS** | almost geometry-only, so a strong check |
| docking final |r| | m | &le; 0.05 | 3.34221e-16 | - | - | **PASS** | the approach must actually reach the port |
| hold arrival |r - r_hold| | m | &le; 0.01 | 8.52651e-14 | - | - | **PASS** |  |
| hold arrival |v| | m/s | &le; 0.001 | 6.93889e-18 | - | - | **PASS** |  |

## G. Perturbed dynamics (Cowell)

| quantity | unit | ref / limit | obtained | abs. err | rel. err | verdict | note |
|---|---|---|---|---|---|---|---|
| central acceleration at R1 | m/s^2 | 1.45 | 1.45223 | 0.00223 | 1.54e-03 | **PASS** |  |
| J2 acceleration at R1 | m/s^2 | 0.0004 | 0.000395966 | 4.03e-06 | 1.01e-02 | **PASS** | a factor 1e3 here means km and m were mixed |
| Earth 3rd-body at R1 | m/s^2 | 2.6e-05 | 2.57882e-05 | 2.12e-07 | 8.15e-03 | **PASS** |  |
| J2-only rendezvous miss | m | 14560.8 | 15139.9 | 579 | 3.98e-02 | **PASS** | no retargeting; FAIL outside 1-80 km |
| J2 + third-body miss | m | 14445.1 | 15024.2 | 579 | 4.01e-02 | **PASS** |  |
| third-body contribution alone | m | 116 | 115.745 | 0.255 | 2.20e-03 | **PASS** | tests the Battin indirect term; FAIL outside 5 m - 5 km |

## H. CR3BP verification

| quantity | unit | ref / limit | obtained | abs. err | rel. err | verdict | note |
|---|---|---|---|---|---|---|---|
| shooting miss distance | m | &le; 1 | 4.77143e-08 | - | - | **PASS** | converged; the shooter is deliberately not restarted |
| extra dV vs the two-body design | mm/s | 1.5 | 8.83753 | 7.34 | 4.89e+00 | **WARN** | same order as the reference optimiser; see the note below |
| TOF shift as a fraction of the coast | % | &le; 0.5 | 0.022129 | - | - | **PASS** | reference optimiser reported +17.1 s, we get -0.88 s |
| Jacobi constant relative drift | - | &le; 1e-06 | 9.14803e-13 | - | - | **PASS** | exact invariant of the CR3BP; measures integration quality only |

## I. Manipulator

| quantity | unit | ref / limit | obtained | abs. err | rel. err | verdict | note |
|---|---|---|---|---|---|---|---|
| FK end-effector position error | m | &le; 0.005 | 5.70281e-05 | - | - | **PASS** | reference pose theta = [0 45 0 60 0] deg, p_mount = 0 |
| FK rotation vs Ry(105 deg) | - | &le; 0.002 | 2.48253e-16 | - | - | **PASS** |  |
| max cylinder Ixx error | kg m^2 | &le; 0.02 | 0.00583333 | - | - | **PASS** | against the design inertia table |
| max cylinder Izz error | kg m^2 | &le; 0.02 | 0.005 | - | - | **PASS** |  |
| base force residual  ||f0|| - ||F|| | N | &le; 1e-06 | 2.24693e-14 | - | - | **PASS** | static chain loaded by a single external force |
| N-transpose vs Jacobian-transpose torques | N m | &le; 1e-06 | 1.1724e-13 | - | - | **PASS** | two independent routes to the same joint torques |
| WDLS position residual | mm | &le; 1.5 | 0.99053 | - | - | **PASS** |  |
| WDLS iterations | - | &le; 80 | 18 | - | - | **PASS** |  |

## J. Build artefacts

| quantity | unit | ref / limit | obtained | abs. err | rel. err | verdict | note |
|---|---|---|---|---|---|---|---|
| metrics.json is parseable | - | n/a | 1 | - | - | **PASS** | 3352 bytes, escapes valid |

---

# Interpretation

## 1. The HCW axis convention, settled empirically

The linear system carried by `lib/relative/phi_hcw.m` is

```
xdd - 2 n zdot           = 0
ydd + n^2 y              = 0
zdd + 2 n xdot - 3 n^2 z = 0
```

The Coriolis signs are the mirror image of the textbook radial/along-track
ordering, which is the classic place to hide a sign error. The triad is

- `x` = V-bar, positive in the **trailing** direction (`x = -v_hat`)
- `y` = cross-track, along the **negative** orbit normal (`y = -h_hat`)
- `z` = R-bar, radial, positive outward (`z = +r_hat`)

This triad is right-handed (`x` x `y` = `(-v)` x `(-h)` = `v` x `h` = `r` = `z`),
and in it the orbital angular velocity is `-n` about the frame's own `y` axis.
That single fact produces both flipped Coriolis signs.

Two independent checks agree that this is the intended convention:

1. **Physics.** Released 100 m radially outward at zero relative velocity, the
   chaser is higher and slower and must fall behind. The STM gives
   x = +11310 m after three orbits, and +x is the trailing direction, so it has
   indeed fallen behind. Reading +x as "ahead" is the trap; the sign is correct
   once the direction of the axis is stated.
2. **Cross-check.** Fed the independent reference injection error
   `dr0 = [207.6; -126.1; 634.6] m`, `dv0 = [0.0087; 0.1478; 0.2944] m/s`, our targeting
   returns `|dV1| = 1.071 m/s` and `dV_hold = 1.419 m/s` against that write-up's
   1.1 and 1.4 m/s. The mirrored convention `Phi(t,-n)` returns 1.277 m/s and does
   not reproduce it. The implemented convention is therefore the one the
   reference geometry assumes, and it is now documented in the function header
   rather than left implicit.

Operationally this is also the natural choice: a "50 m V-bar hold" is 50 m
astern, and the forced approach walks `x` from +50 m down to 0 at the port.

## 2. Docking delta-v: 0.1567 vs 0.1567 m/s

The forced V-bar profile is almost pure geometry: five equal legs from 50 m to
the port in 1000 s, plus a braking impulse. Agreement to better than 0.1 % with
an independent implementation means the leg targeting, the waypoint spacing and
the brake are all modelled the same way. This is the single strongest
confirmation in the audit that the proximity module is faithful.

## 3. Third-body contribution: 115.7 vs 116.0 m

Agreement at the 0.2 % level on a 116 m effect confirms two things that are
easy to get wrong: the Battin difference form retains its indirect term
`-mu_E * r_E/|r_E|^3`, which removes the acceleration of the Moon-centered
origin, and the Earth ephemeris uses the synodic rate
`n_EM = sqrt((mu_M + mu_E)/d_EM^3)`. Dropping the indirect term inflates this
number by orders of magnitude, so a match this tight is a real test.

## 4. J2 miss: 15.14 km vs 14.56 km (+4.0 %)

Same order, within the 20 % band, so this is a PASS rather than a defect. The
four candidate causes named in the audit plan were checked in the source rather
than assumed:

- The departure impulse is applied along the **perturbed** velocity unit vector
  sampled at `t_wait`, not along the Keplerian direction (`fly_lm` in
  `parts/part3_perturbations.m`).
- The mothership is propagated with the **same** perturbed dynamics as the
  chaser; only their initial states differ.
- The J2 acceleration uses the full three-component formula, which correctly
  reduces to a purely radial correction at z = 0 instead of being special-cased.
- Integration runs at RelTol = AbsTol = 1e-10, and the Keplerian control case
  through the identical code path closes to 5.6e-03 m, so the residual is physics,
  not integrator noise.

The remaining few percent is sensitivity, not error. The miss is dominated by a
secular along-track phase slip driven by the difference in `1.5*J2*(R/r)^2`
between the two radii, accumulated over 10.5 hours. A quantity built from a
difference of two nearly equal slips is intrinsically sensitive to the exact
epoch of the burn and to the tolerance of the propagator, so two correct
implementations agreeing to 4 % is the expected outcome. It has not been tuned.

## 5. Hold delta-v: 1.123 vs 1.4 m/s

Not comparable directly: the injection error is a random draw and the two runs
use different realisations. Ours comes from `rng(42)` and is
|dr0| = 529.0 m, |dv0| = 0.8796 m/s. Fed the reference draw instead, our own
targeting returns 1.419 m/s, reproducing the reference. The official run keeps
`rng(42)` so the repository stays reproducible.

## 6. CR3BP: 8.8 mm/s vs 1.5 mm/s, TOF -0.9 s vs +17.1 s

The shooter converges to a miss of 4.8e-08 m, so it is not restarted.

Both figures say the same operational sentence: a 100 km lunar orbit sits deep
enough in the lunar potential well that Earth tides move the two-impulse budget
by **millimetres per second**, against a 118.80 m/s transfer. That is a relative
effect of order 1e-4 and it is below the noise of any real navigation solution.

The spread between 1.5 and 8.8 mm/s is an optimiser artefact, not a physics
disagreement. With only two independent miss components in a planar problem and
three decision variables, the zero-miss set is a curve rather than a point, so
every point on it is a valid solution with a slightly different delta-v and time
of flight. `shoot_cr3bp_transfer.m` regularises towards the two-body guess to
pick the smallest correction on that curve; a different Nelder-Mead start lands
elsewhere on the same curve. Our TOF shift of -0.88 s is 0.022 % of the 3975 s
coast; the reference's +17.1 s is 0.43 %. Neither is operationally meaningful,
and forcing our optimiser to reproduce +17.1 s would be curve-fitting.

## 7. What was changed as a result of this audit

- `lib/relative/phi_hcw.m`: the axis convention is now stated explicitly, with
  the handedness argument and the empirical arbiter, instead of being described
  loosely as "non-standard".
- `build_all.m`: `metrics.json` emitted bare Windows backslashes, which made the
  file unparseable by any JSON reader. Paths are now repo-relative and POSIX.
- `parts/part5_cr3bp.m`: the full non-dimensional synodic state history is saved
  so the Jacobi constant can be checked.
- No physics constant, model or solver was changed. Nothing was tuned towards a
  reference number.
