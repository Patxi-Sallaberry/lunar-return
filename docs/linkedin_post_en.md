# LinkedIn post — English version

Post with `results/video/showreel_square.mp4` (1080×1080) or `showreel.mp4`
(1920×1080, 89 s). About 1,250 characters.

---

A crew lifts off from the Moon. Their ascent stage reaches 100 km carrying the
dispersion a single-string engine always leaves behind. The mothership is 300 km
higher. I simulated everything that happens next.

🌑 Hohmann transfer 100 → 400 km: ΔV = 118.80 m/s. But the phasing window has
just been missed, so the vehicle waits 9.44 h before lighting the engine. The
transfer itself lasts 66 minutes — on this kind of rendezvous the binding
constraint is time, not propellant.

🎯 Numerical propagation validated against the closed-form Kepler solution:
0.19 mm over 10.5 h of flight. That number is what makes everything downstream
trustworthy.

🛰️ Hill–Clohessy–Wiltshire proximity operations: a 529 m injection error becomes
a 21 km drift in three orbits. Two impulses to acquire the 50 m V-bar hold, then
a forced five-leg straight-line approach to the port. Total 1.28 m/s — about 1 %
of the transfer budget.

🌍 Lunar J2 plus Earth third body, flown without retargeting: the Keplerian
design misses by 15.1 km. The Earth accounts for only 116 m of it. At this
altitude lunar oblateness dominates, not the Earth — the opposite of the
intuition you bring from Earth orbit.

🦾 5R berthing arm: kineto-static duality, 396 N·m at the shoulder under a 100 N
load. Weighted damped least-squares inverse kinematics, 0.99 mm in 18 iterations.

Every figure is re-derived independently by an audit script: 60 PASS, 1 WARN,
0 FAIL. The one remaining discrepancy is documented, not tuned away.

29-page PDF report, 20 figures, 89 s showreel:
https://github.com/Patxi-Sallaberry/lunar-return-rendezvous

#Aerospace #MATLAB #OrbitalMechanics #SpaceRobotics
