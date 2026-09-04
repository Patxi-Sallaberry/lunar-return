# Post LinkedIn — version française

À publier avec `results/video/showreel_square.mp4` (1080×1080) ou `showreel.mp4` (1920×1080).
Environ 1 250 caractères.

---

Un équipage décolle de la Lune. Son étage de remontée atteint une orbite à 100 km avec la dispersion
qu'un moteur non redondant laisse toujours derrière lui. Le vaisseau-mère est 300 km plus haut.
Personne ne vient les chercher.

J'ai simulé tout ce qui se passe ensuite, en MATLAB, à partir de zéro.

🌑 Attente de phasage puis transfert de Hohmann, 100 → 400 km : ΔV = 118,80 m/s. La fenêtre vient
d'être manquée, donc 9,44 h d'attente avant l'allumage.

🎯 Vérification numérique contre la solution analytique de Kepler : 1,9 × 10⁻⁴ m d'écart sur dix
heures de vol. C'est ce chiffre qui rend crédible tout le reste.

🛰️ Opérations de proximité en Hill-Clohessy-Wiltshire : l'erreur d'injection devient 21 km de dérive
en trois orbites. Deux impulsions pour tenir le point d'attente à 50 m, puis une approche V-bar
forcée en cinq segments jusqu'au port. Coût total : 1,28 m/s.

🌍 Perturbations J2 lunaire + troisième corps Terre, sans re-ciblage : le design keplérien rate le
rendez-vous de 15,1 km. La Terre seule en explique 116 m.

🦾 Bras de berthing 5R : cinématique directe, matrice de propagation des torseurs 36×11, dualité
cinéto-statique. 396 N·m à l'épaule sous 100 N. Cinématique inverse en moindres carrés amortis
pondérés : 0,99 mm en 18 itérations — un bras à 5 axes ne peut pas servir 6 DDL, et le solveur le dit.

Stack : MATLAB, ode45, matrice de transition HCW, Cowell J2 + 3 corps, tir simple CR3BP, WDLS.
Aucune toolbox. Les figures et la vidéo sont générées par le même script.

Code et vidéo : https://github.com/<user>/lunar-return-rendezvous

#Aerospace #MATLAB #OrbitalMechanics #SpaceRobotics
