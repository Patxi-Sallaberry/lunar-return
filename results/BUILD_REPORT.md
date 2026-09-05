# Build report

This is the overnight summary. Read it before anything else.

- date: 2026-09-05 10:42:05
- MATLAB: 2026a on PCWIN64
- ffmpeg: wsl
- elapsed: 01:22
- figures: 20 PNG
- clips: 0.0 s across 0 files; the showreel concatenates the seven numbered ones

| stage | result |
|---|---|
| Part 1  orbital transfer         | PASS |
| Part 2  proximity operations     | PASS |
| Part 3  perturbations            | PASS |
| Part 4  manipulator statics      | PASS |
| Part 5  CR3BP transfer           | PASS |
| Part 6  inverse kinematics       | PASS |
| fig18 lander schematic           | PASS |

## Clips

| clip | seconds | encoder |
|---|---|---|

## Headline numbers

| quantity | value |
|---|---|
| Hohmann dV total [m/s] | 118.8 |
| Phasing wait [h] | 9.441 |
| Mission duration [h] | 10.55 |
| Num-vs-analytic error [m] | 0.0001912 |
| Injection error [m] | 529 |
| Hold acquisition dV [m/s] | 1.123 |
| Docking dV [m/s] | 0.1567 |
| J2 miss [km] | 15.14 |
| J2 + 3B miss [km] | 15.02 |
| Third-body only [m] | 115.7 |
| Mid-course correction [m/s] | 0.8908 |
| CR3BP miss [m] | 4.771e-08 |
| CR3BP extra dV [mm/s] | 8.838 |
| Arm reach [m] | 7.7 |
| Peak joint torque [N m] | 396.5 |
| IK residual [mm] | 0.9905 |
| IK iterations | 18 |

No part failed. Stack traces, if there had been any, would be in results/FAIL_partN.txt.
