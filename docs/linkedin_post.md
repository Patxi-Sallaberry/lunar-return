# Post LinkedIn — version française

À publier avec `results/video/showreel.mp4` (89 s) ou le format carré
`showreel_square.mp4`. Environ 1 050 caractères.

---

Le transfert dure 66 minutes. L'attente pour pouvoir l'entamer en dure 9,4.

C'est le résultat qui m'a le plus surpris en simulant le retour d'un équipage
depuis la Lune : un étage de remontée à 100 km, un vaisseau-mère 300 km plus
haut, et une fenêtre de phasage qu'on vient de manquer. Sur ce type de
rendez-vous, l'ergol est bon marché — c'est la patience qui contraint
l'architecture.

Trois chiffres :

→ 118,80 m/s pour le transfert de Hohmann complet.

→ 0,19 mm d'écart entre la propagation numérique et la solution analytique de
Kepler sur 10,5 h de vol. C'est ce contrôle qui rend crédible tout le reste.

→ 15,1 km de rendez-vous manqué sous J2 sans re-ciblage, corrigés pour 0,89 m/s
si la correction est placée tôt. Le même re-ciblage à mi-transfert en coûte
12,6 : le prix d'une manœuvre dépend d'abord de sa date.

Écrit en MATLAB de base — `ode45` et `fminsearch`, aucune toolbox. Chaque
grandeur est recalculée en forme fermée par un script d'audit qui tourne à
chaque build : 70 PASS, 0 FAIL. Rapport de 32 pages et showreel dans le dépôt.

https://github.com/Patxi-Sallaberry/lunar-return

#astrodynamics #MATLAB #rendezvous
