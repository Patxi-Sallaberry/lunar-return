# Physics notes

Short derivations for the choices made in the code. Every equation here maps to a named function.

---

## 1. Why the chaser waits 9.44 hours

The Hohmann transfer between two coplanar circular orbits sweeps exactly π radians of true anomaly.
During that time the target advances by `n₂·Δt_tof`. For the two to arrive at the same point, the
target must lead the chaser at ignition by

```
Δθ_H = π − n₂·Δt_tof = 0.32484 rad = 18.61°
```

At t = 0 the target leads by only φ₀ = 10°. Because the inner orbit is faster, the target's lead as
seen from the chaser *decreases*, so 10° will not grow back into 18.61° — it has to run all the way
down through zero and around again:

```
Δθ_req = 2π − (Δθ_H − φ₀) = 351.39°
t_wait = Δθ_req / |n₂ − n₁| = 33 988 s = 9.44 h
```

`phasing_wait.m` implements the general conditional, so a geometry where the window has *not* been
missed (Δθ_H < φ₀) takes the short branch instead.

The rendezvous is exact by construction. At arrival the chaser is at `n₁·t_wait + π` and the target
at `φ₀ + n₂·(t_wait + Δt_tof)`; subtracting and substituting `t_wait` gives a difference of exactly
2π. `part1_orbital_transfer.m` verifies this numerically: the miss is 5.6 × 10⁻⁵ m, which is
integrator noise, not geometry.

---

## 2. The verification that makes the rest credible

The transfer is propagated twice. Numerically:

```
ṙ = v,    v̇ = −μ r / |r|³          (fr2b.m, ode45, RelTol = AbsTol = 1e-12)
```

Analytically, through Kepler's equation solved by Newton–Raphson to 1e-14:

```
M = n_H (t − t_wait)
E_{k+1} = E_k − (E_k − e sin E_k − M) / (1 − e cos E_k)
r_pf = [a(cos E − e);  a√(1−e²) sin E;  0]
```

rotated into MCI by `Rz(θ_p)` so that periapsis sits at the ignition longitude
(`analytical_kepler_state.m`).

Over the ten-hour timeline the two agree to **1.9 × 10⁻⁴ m**. That is the licence to trust every
perturbed result downstream: when the J2 run later reports a 15 km miss, we know 15 km is physics and
not integrator drift, because the same integrator reproduces the analytical solution to a fifth of a
millimetre.

The specific energy, angular momentum and eccentricity are piecewise constant across the three legs
and match the analytical plateaus:

| leg | e | \|h\| [km²/s] | ε [km²/s²] |
|---|---|---|---|
| inner circular | 0 | 3001.40 | −1.33417 |
| transfer ellipse | 0.075475 | 3112.61 | −1.23347 |
| outer circular | 0 | 3237.17 | −1.14691 |

---

## 3. HCW in this project's axis convention

The linearised relative motion about a circular chief is written here with

- `x` along-track (V-bar), `y` cross-track, `z` radial (R-bar):

```
ẍ − 2n ż                = 0
ÿ + n² y                = 0
z̈ + 2n ẋ − 3n² z        = 0
```

This is the textbook system with the radial and along-track roles exchanged, which flips the sign of
the Coriolis coupling. It is easy to mistake for an error; `test_hcw_stm_identity.m` differentiates
the closed-form state transition matrix at t = 0 and compares it with the system matrix A, so the
signs are pinned by a test rather than by a comment.

Targeting is then one linear solve. To reach `r_hold` in Δt:

```
v₀⁺  = Φ_rv(Δt)⁻¹ (r_hold − Φ_rr(Δt) r₀)
Δv₁  = v₀⁺ − v₀
Δv₂  = v_hold − (Φ_vr r₀ + Φ_vv v₀⁺)
```

`Φ_rv` is singular whenever Δt approaches a multiple of the orbital period, because after a full
revolution the initial velocity no longer controls the final position. Both `two_impulse_hold.m` and
`forced_vbar_docking.m` check `rcond` and walk Δt by 1 % until the solve is safe, reporting the nudge.

**Validity.** The linearisation error grows with ρ/R₂. At the 21 km the uncorrected drift reaches,
that ratio is ~10⁻², and the nonlinear model departs from HCW by about 100 m after three orbits. At
the 50 m hold point it is 2.3 × 10⁻⁵, and the two models agree to well under a millimetre. The
approximation is used exactly where it is good.

---

## 4. Why J2 moves a rendezvous that never leaves the equator

For an equatorial orbit z ≡ 0, so

```
a_J2 = 1.5 J₂ μ R² / r⁴ · [ (x/r)(5(z/r)² − 1); (y/r)(5(z/r)² − 1); (z/r)(5(z/r)² − 3) ]
```

collapses to `−1.5 J₂ μ R² / r⁵ · [x; y; 0]`: a purely radial correction. It does not tilt the plane
and it does not precess the node. What it does is stiffen the central field by a *radius-dependent*
amount:

```
δa_r / a_r = 1.5 J₂ (R_Moon / r)²
```

which is 2.73 × 10⁻⁴ at 100 km altitude and 2.01 × 10⁻⁴ at 400 km. A circular orbit responds with
δn/n = ½ δμ_eff/μ, so the two vehicles accumulate *different* along-track phase. Over 10.5 hours that
difference is kilometres. The simulation measures **15.1 km**.

The third-body term uses Battin's difference form:

```
a_3B = μ_E ( (r_E − r)/|r_E − r|³ − r_E/|r_E|³ )
```

The second term is the indirect part: it removes the acceleration of the origin, because the frame is
Moon-centered and the Moon is itself falling towards the Earth. Dropping it inflates the effect by
orders of magnitude — a classic error. With it, the Earth contributes **116 m** to the miss.

### Acceleration budget at r = R₁

| source | magnitude [m/s²] | ratio to central |
|---|---|---|
| central | 1.452 | 1 |
| lunar J2 | 3.96 × 10⁻⁴ | 2.7 × 10⁻⁴ |
| Earth third body | 2.58 × 10⁻⁵ | 1.8 × 10⁻⁵ |
| solar radiation pressure | ~10⁻⁷ | ~7 × 10⁻⁸ |

**On solar radiation pressure.** For a vehicle with an area-to-mass ratio of order 0.01 m²/kg and a
reflectivity near 1.3, the solar flux at 1 AU gives a cannonball acceleration around 10⁻⁷ m/s², and a
large deployed array can push that to 10⁻⁶. That is two to three orders of magnitude below J2 here.
It is also intermittent: a 100 km lunar orbit has a period near two hours and spends roughly 30–40 %
of each revolution in the Moon's shadow, so the perturbation switches on and off rather than
accumulating smoothly. Over a ten-hour mission the integrated velocity change is of order
10⁻³ m/s — three orders below the mid-course correction J2 already demands. It is therefore estimated
and excluded rather than integrated. `C.enableSRP` exists as a flag; the cannonball model is not
wired in, and the README says so.

### Mitigation, if this were a real flight plan

- **Frozen orbits.** Choosing eccentricity and argument of periapsis so that the secular J2 rates
  cancel removes most of the drift for the target. Under the real lunar field, dominated by mascons
  rather than a clean J2, this becomes a numerical search rather than a closed form, and it is out of
  scope here.
- **Co-elliptic rendezvous.** Flying the approach on orbits with the same period rather than the same
  shape makes the relative geometry insensitive to a common-mode field error.
- **Mid-course correction.** The direct answer: budget an impulse of order `n₂·|miss| ≈ 10.7 m/s` at
  roughly the halfway point. This is 9 % of the nominal 118.8 m/s transfer budget, which is a
  realistic number for a design of this fidelity.

---

## 5. Synodic frame bookkeeping

The CR3BP is integrated in a barycentric rotating frame with μ = 0.01215, the Earth at −μ and the
Moon at 1−μ, in units LU = 384 400 km and TU = √(LU³/(μ_E + μ_M)) = 375 191 s.

The conversion from a Moon-centered inertial state is, in order: rotate into the frame whose +x is the
Earth–Moon line, translate the origin to the barycentre and scale, then subtract the frame rotation
and add the Moon's own inertial velocity:

```
r_syn = Rz(−α) r_MCI / LU + [1−μ; 0; 0]
v_syn = Rz(−α) v_MCI / VU + [0; 1−μ; 0] − ω × r_syn,   ω = [0;0;1]
```

with α the MCI longitude of the Earth-to-Moon direction. Component-wise this is
`vx_syn = vx_in + y_syn` and `vy_syn = vy_in − x_syn + (1−μ)`, which is where the (1−μ) that looks
mysterious in the assignment comes from: it is the Moon's own velocity about the barycentre.

The unit test is unambiguous: a body sitting at the Moon's centre with zero inertial velocity must
come out with **exactly zero** synodic velocity, because in the rotating frame the Moon does not move.
`test_cr3bp_frame.m` checks that, plus the Earth landing at −μ, plus a round trip.

**Why the shooting problem is regularised.** The decision vector is [δvₓ, δv_y, TOF], three unknowns,
but the planar miss has only two independent components. The zero-miss set is therefore a curve, not
a point, and an unregularised `fminsearch` wanders along it and reports an arbitrary member of a
family. `shoot_cr3bp_transfer.m` adds a small penalty on the distance from the two-body guess, weighted
so it can never dominate the miss term (10⁻³ km per unit relative deviation, i.e. a 1 % deviation costs
one centimetre of apparent miss). The reported correction is then the *smallest* one, which is the
only version of the number that means anything.

---

## 6. Kineto-statics of a free-flying chain

The system Jacobian maps eleven generalised velocities to six body twists:

```
t = N u,   u = [ω₀; ṙ₀; q̇₁..₅] ∈ R¹¹,   t ∈ R³⁶,   N = N_l N_d
```

`N_d = blkdiag(I₆, p₁, …, p₅)` injects each joint rate into its own body, with
`p_i = [e_i; e_i × g_i]` in inertial axes and `g_i` the joint-to-centre-of-mass offset. `N_l` is block
lower triangular with unit diagonal and rigid-body transports

```
B_ij = [ I₃      0  ;
         [r_j − r_i]×   I₃ ]
```

The sign matters and is easy to get backwards: `v_i = v_j + ω_j × (r_i − r_j)` and
`ω_j × d = −[d]× ω_j`, hence `[r_j − r_i]×`.

Static equilibrium in micro-gravity, with only the end effector loaded, gives `τ = Nᵀ w`, and the
actuators plus the attitude control system must supply `−τ`. Two consequences are checked as tests:

1. The force part of the base reaction equals the applied contact force **exactly**, and the moment
   part equals `M_tip + (r_tip − r_base) × F`. Residual: 2 × 10⁻¹⁴.
2. The joint torques from the 36-body route equal `J_geomᵀ [f; n]` from the 6 × 5 end-effector
   Jacobian. Residual: 1 × 10⁻¹³.

Two entirely different pieces of algebra agreeing to machine precision is worth more than either one
looking plausible.

Note that **mass never appears**. In micro-gravity the static problem is mass-free; the inertias
computed in `manipulator_params.m` would enter H and C in the free-floating dynamics, which is
deliberately not integrated here.

---

## 7. Why the inverse kinematics has a residual and that is correct

A 5R arm spans a five-dimensional subspace of the six-dimensional task space. Asking for an exact
pose is asking for something that generically does not exist. Weighted damped least squares makes the
trade explicit:

```
θ ← θ + α (Jᵀ W J + λ² I)⁻¹ Jᵀ W Δx,    Δx = [Δp; e_o]
```

with W = diag(1, 1, 1, 1, 1, 0.01). The orientation error uses the Siciliano form

```
e_o = ½ (x × x_t + y × y_t + z × z_t)
```

rather than axis-angle extraction, which is singular at ±180° — and the seeds used here start far
from the target, so large rotations genuinely occur on the first iterations.

The zero pose is a real singularity for this chain: fully extended along z, joint 1 produces no
end-effector translation at all, so the position Jacobian loses a column. The solver escapes it
because the attitude term still torques joint 1, but `part6_inverse_kinematics.m` carries a
deterministic seed cascade anyway and logs which seed was used. On the reachable target it converges
to **0.99 mm in 18 iterations**.

Interesting detail: the solution found is *not* the configuration the target was generated from.
q* = [40.0, 16.3, 20.1, 28.6, 25.0]° reaches the pose of q_arb = [40, 35, −20, 50, 25]° because joints
2, 3 and 4 all rotate about the same axis and only their sum matters — 65° in both cases. Multiple
inverse solutions are the expected behaviour, not a bug.
