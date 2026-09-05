# Retour depuis l'orbite lunaire — simulation numérique de bout en bout

**Une page. Projet personnel, MATLAB, sans toolbox.**

---

## Le problème

Un équipage décolle de la Lune. Son étage de remontée atteint une orbite
circulaire à 100 km avec la dispersion qu'un moteur non redondant, sans
stabilisation aérodynamique et à centre de masse mobile laisse forcément
derrière lui. Le vaisseau-mère est 300 km plus haut et 10° en avance. J'ai
simulé tout ce qui se passe entre ces deux états, de l'attente de phasage
jusqu'à la capture par un bras robotique.

## Cinq chiffres

| | |
|---|---|
| Transfert de Hohmann 100 → 400 km | **118,80 m/s** de ΔV, après **9,44 h** d'attente de fenêtre |
| Validation numérique contre Kepler analytique | **0,19 mm** d'écart sur 10,5 h de vol |
| Opérations de proximité (HCW) | erreur d'injection de 529 m → dérive de **21 km** en 3 orbites, corrigée pour **1,28 m/s** au total |
| Perturbations J2 + 3ᵉ corps, sans re-ciblage | rendez-vous manqué de **15,1 km**, dont **116 m** dus à la Terre |
| Cinématique inverse du bras 5R | **0,99 mm** de résidu en 18 itérations |

Le point le plus instructif du projet n'est pas le ΔV : c'est le rapport des
échelles de temps. Le transfert dure 66 minutes, l'attente de phasage 9,4 heures.
Sur ce type de rendez-vous, l'ergol est bon marché et c'est la patience qui
contraint l'architecture.

## Ce qui est vérifié

Chaque grandeur est recalculée indépendamment : en forme fermée à partir des
constantes brutes, ou comparée à une implémentation indépendante de la même
géométrie de mission. Un script d'audit rejoue ces contrôles à chaque build et
produit un tableau PASS / WARN / FAIL — **60 PASS, 1 WARN, 0 FAIL**. Le seul
avertissement (correction CR3BP de 8,8 mm/s contre 1,5 mm/s pour un optimiseur
de référence) est documenté comme un artefact d'optimiseur sur un problème de
tir sous-déterminé, pas comme un désaccord physique. Rien n'a été ajusté pour
ressembler à une référence.

## Une limite assumée

Les orbites sont équatoriales et coplanaires. Il n'y a donc ni changement
d'inclinaison ni régression nodale, alors que c'est précisément le poste qui
domine le budget d'un rendez-vous réel. C'est l'omission la plus importante du
modèle, et elle est explicite dans le rapport plutôt que passée sous silence.

## Comment l'exécuter

```matlab
>> run_all
```

Une dizaine de minutes sans intervention : environ une minute de physique, le
reste en rendu vidéo. MATLAB de base uniquement — `ode45` et `fminsearch`, aucune
toolbox, aucune éphéméride externe, aucune image téléchargée. La sortie
comprend 20 figures, un rapport PDF de 29 pages, un showreel de 89 s et un
tableau d'audit.

**Stack :** MATLAB · ode45 · matrice de transition HCW · Cowell J2 + 3 corps ·
tir simple CR3BP · moindres carrés amortis pondérés.
