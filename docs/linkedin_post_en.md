# LinkedIn post — English version

Post with `results/video/showreel_square.mp4` (1080×1080) or `showreel.mp4` (1920×1080).
About 1,250 characters.

---

A crew lifts off from the Moon. Their ascent stage reaches a 100 km orbit carrying the dispersion a
single-string engine always leaves behind. The mothership is 300 km higher. Nobody is coming to help.

I simulated everything that happens next, in MATLAB, from scratch.

🌑 Phasing wait then Hohmann transfer, 100 → 400 km: ΔV = 118.80 m/s. The window has just been
missed, so the chaser waits 9.44 h before lighting the engine.

🎯 Numerical propagation checked against the closed-form Kepler solution: 1.9 × 10⁻⁴ m over ten hours
of flight. That number is what makes everything downstream trustworthy.

🛰️ Hill–Clohessy–Wiltshire proximity operations: the injection error becomes a 21 km drift in three
orbits. Two impulses to acquire the 50 m V-bar hold, then a forced five-leg straight-line approach to
the port. Total cost: 1.28 m/s.

🌍 Lunar J2 plus Earth third body, flown without retargeting: the Keplerian design misses the
rendezvous by 15.1 km. The Earth alone accounts for 116 m of it.

🦾 5R berthing arm: forward kinematics, a 36×11 twist-propagation matrix, kineto-static duality.
396 N·m at the shoulder under a 100 N berthing load. Weighted damped least-squares inverse
kinematics: 0.99 mm in 18 iterations — a five-joint arm cannot serve six task DOF, and the solver
says so instead of hiding it.

Stack: MATLAB, ode45, HCW state transition matrix, Cowell J2 + third body, CR3BP single shooting,
WDLS. No toolboxes. Figures and video come out of the same script.

Code and video: https://github.com/<user>/lunar-return-rendezvous

#Aerospace #MATLAB #OrbitalMechanics #SpaceRobotics
