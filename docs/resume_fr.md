# Retour depuis l'orbite lunaire — simulation numérique de bout en bout

**Projet personnel, MATLAB, sans toolbox.** Rapport complet : 32 pages, PDF dans
`results/report/`.

---

## Le problème

Un équipage décolle de la Lune. Son étage de remontée atteint une orbite
circulaire à 100 km avec la dispersion qu'un moteur non redondant, sans
stabilisation aérodynamique et à centre de masse mobile laisse forcément
derrière lui. Le vaisseau-mère est 300 km plus haut et 10° en avance. J'ai
simulé tout ce qui se passe entre ces deux états, de l'attente de phasage
jusqu'à la capture par un bras robotique.

## Six chiffres

| | |
|---|---|
| Transfert de Hohmann 100 → 400 km | **118,80 m/s** de ΔV, après **9,44 h** d'attente de fenêtre |
| Validation numérique contre Kepler analytique | **0,19 mm** sur 10,5 h de vol |
| Opérations de proximité (HCW) | erreur d'injection de 529 m → **21 km** de dérive en 3 orbites, corrigée pour **1,28 m/s** |
| Perturbations J2 + 3ᵉ corps, sans re-ciblage | rendez-vous manqué de **15,1 km**, dont **116 m** dus à la Terre |
| Correction mi-course, vrai re-ciblage | **0,89 m/s** — et non les 10,7 m/s que donne l'estimation naïve |
| Cinématique inverse du bras 5R | **0,99 mm** de résidu en 18 itérations |

Le point le plus instructif n'est pas le ΔV, c'est le rapport des échelles de
temps : le transfert dure 66 minutes, l'attente de phasage 9,4 heures. Sur ce
type de rendez-vous, l'ergol est bon marché et c'est la patience qui contraint
l'architecture.

Le deuxième point est le coût d'une correction. Un écart de 15 km est une erreur
de **phase** (7 mrad), pas une erreur de position : on l'achète avec du temps,
pas avec de la poussée. Corrigée à mi-mission elle coûte 0,89 m/s ; la même
correction appliquée à mi-transfert, avec 33 minutes de bras de levier au lieu
de 5 heures, en coûte 12,6. Le prix d'une manœuvre dépend d'abord de la date à
laquelle on la fait.

## Ce qui est vérifié

Chaque grandeur est recalculée indépendamment : en forme fermée depuis les
constantes brutes, ou comparée à une implémentation indépendante de la même
géométrie de mission. Un script d'audit rejoue ces contrôles à chaque build —
**70 PASS, 1 WARN, 0 FAIL**. Le seul avertissement concerne la correction CR3BP,
et il est traité en publiant la famille de solutions plutôt qu'un point isolé :
le problème de tir plan est sous-déterminé d'un rang, donc dix membres ferment
le rendez-vous à moins d'un mètre sur une fenêtre de ±40 s de temps de vol.
Rien n'a été ajusté pour ressembler à une référence.

La convention d'axes du repère relatif a été tranchée par un test, pas par un
commentaire : parmi les trois lectures possibles, une seule reproduit le ΔV de
l'implémentation de référence (1,419 contre 1,4 m/s). C'est cette convention qui
est retenue, et le rapport dit explicitement qu'elle n'est **pas** celle de
Fehse — le +V-bar y est mesuré vers l'arrière.

## Une limite assumée

Les orbites sont équatoriales et coplanaires : ni changement d'inclinaison, ni
régression nodale, alors que c'est précisément le poste qui domine le budget
d'un rendez-vous réel. C'est l'omission la plus importante du modèle, et elle
est explicite dans le rapport plutôt que passée sous silence.

## Comment l'exécuter

```matlab
>> run_all                  % physique, figures et audit, ~90 s
>> build_all('--video')     % plus le showreel de 89 s
>> build_all('--verify')    % toutes les tolérances resserrées
```

MATLAB de base uniquement — `ode45` et `fminsearch`, aucune toolbox, aucune
éphéméride externe, aucune image téléchargée. `ffmpeg` assemble le showreel,
`latexmk` compile le rapport.

J'ai utilisé Claude Code comme agent de développement pour la structure du
dépôt, le code répétitif, le gabarit LaTeX et la boucle de build non
supervisée. L'autorité sur la justesse reste `tests/audit_reference.m`, qui
recalcule chaque grandeur en forme fermée depuis les constantes brutes : quand
l'audit et le texte se contredisaient, c'est le texte qui a été corrigé.

**Stack :** MATLAB · ode45 · matrice de transition HCW · Cowell J2 + 3 corps ·
tir simple CR3BP · moindres carrés amortis pondérés.
