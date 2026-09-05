# Post LinkedIn — version française

À publier avec `results/video/showreel_square.mp4` (1080×1080) ou
`showreel.mp4` (1920×1080, 89 s). Environ 1 250 caractères.

---

Un équipage décolle de la Lune. Son étage de remontée atteint 100 km avec la
dispersion qu'un moteur non redondant laisse toujours derrière lui. Le
vaisseau-mère est 300 km plus haut. J'ai simulé tout ce qui se passe ensuite.

🌑 Transfert de Hohmann 100 → 400 km : ΔV = 118,80 m/s. Mais la fenêtre de
phasage vient d'être manquée, donc 9,44 h d'attente avant l'allumage. Le
transfert dure 66 minutes : ici, c'est le temps qui contraint, pas l'ergol.

🎯 Propagation numérique validée contre la solution analytique de Kepler :
0,19 mm d'écart sur 10,5 h de vol. C'est ce chiffre qui rend crédible tout le
reste.

🛰️ Opérations de proximité en Hill-Clohessy-Wiltshire : une erreur d'injection
de 529 m devient 21 km de dérive en trois orbites. Deux impulsions pour tenir le
point d'attente à 50 m, puis une approche V-bar forcée en cinq segments jusqu'au
port. Total : 1,28 m/s, soit 1 % du budget de transfert.

🌍 J2 lunaire + troisième corps Terre, sans re-ciblage : le design keplérien rate
le rendez-vous de 15,1 km. La Terre n'en explique que 116 m. À cette altitude,
c'est l'aplatissement lunaire qui compte, pas la Terre — l'inverse de l'intuition
qu'on ramène de l'orbite terrestre.

🦾 Bras de berthing 5R : dualité cinéto-statique, 396 N·m à l'épaule sous 100 N.
Cinématique inverse en moindres carrés amortis pondérés, 0,99 mm en 18 itérations.

Chaque chiffre est recalculé indépendamment par un script d'audit :
60 PASS, 1 WARN, 0 FAIL. L'écart qui subsiste est documenté, pas ajusté.

Rapport PDF 29 pages, 20 figures, showreel 89 s :
https://github.com/<user>/lunar-return-rendezvous

#Aerospace #MATLAB #OrbitalMechanics #SpaceRobotics
