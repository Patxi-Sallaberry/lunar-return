# Build report

This is the overnight summary. Read it before anything else.

- date: 2026-09-05 06:14:41
- MATLAB: 2026a on PCWIN64
- ffmpeg: wsl
- elapsed: 08:55
- figures: 20 PNG
- clips: 99.0 s across 8 files; the showreel concatenates the seven numbered ones

| stage | result |
|---|---|
| Part 1  orbital transfer         | PASS |
| Part 2  proximity operations     | PASS |
| Part 3  perturbations            | PASS |
| Part 4  manipulator statics      | PASS |
| Part 5  CR3BP transfer           | PASS |
| Part 6  inverse kinematics       | PASS |
| fig18 lander schematic           | PASS |
| video 01_title                   | PASS |
| video 02_hohmann                 | PASS |
| video 03_proximity               | PASS |
| video 04_perturbations           | PASS |
| video 05_cr3bp                   | PASS |
| video 06_arm                     | PASS |
| video 06b_ik_telemetry           | PASS |
| video 07_endcard                 | PASS |
| showreel.mp4                     | PASS |
| showreel_square.mp4              | PASS |

## Clips

| clip | seconds | encoder |
|---|---|---|
| 01_title | 4.0 | mp4 |
| 02_hohmann | 18.0 | mp4 |
| 03_proximity | 20.0 | mp4 |
| 04_perturbations | 14.0 | mp4 |
| 05_cr3bp | 11.0 | mp4 |
| 06_arm | 16.0 | mp4 |
| 06b_ik_telemetry | 10.0 | mp4 |
| 07_endcard | 6.0 | mp4 |

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
| Mid-course correction [m/s] | 10.73 |
| CR3BP miss [m] | 4.771e-08 |
| CR3BP extra dV [mm/s] | 8.838 |
| Arm reach [m] | 7.7 |
| Peak joint torque [N m] | 396.5 |
| IK residual [mm] | 0.9905 |
| IK iterations | 18 |

No part failed. Stack traces, if there had been any, would be in results/FAIL_partN.txt.
