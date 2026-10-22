Name: Subțirică Florin-Ioan
Group: 332CD

# Tema 3 - optimizări

## Overview
C=(At×B+B×A)×Bt
unde:
A si B sunt matrice pătratice de dimensiune N x N, cu elemente de tip double
A este o matrice superior triunghiulară
At este transpusa lui A și Bt este transpusa lui B
× este operația de înmulțire
+ este operația de adunare
Tema va implementa expresia de mai sus în 3 moduri:
blas - o variantă care folosește una sau mai multe funcții din BLAS Atlas pentru realizarea operațiilor de înmulțire și adunare.
neopt - o variantă “de mână” fără îmbunătățiri.
opt_m - o variantă îmbunătățită a versiunii neopt. Îmbunătățirea are în vedere exclusiv modificarea codului pentru a obține performanțe mai bune.

### solver_neopt.c
Am ales să folosesc vectori și nu matrici, vectorul având toate liniile matricei concatenate intr-un vector de dimensiune N*N. Adică pentru o matrice:
[a b c
d e f
g h i]
eu am pus în vector [a,b,c,d,e,f,g,h,i], deoarece poți folosi face mai ușor operațiile între matrici, plus că așa ni s-a dat și input-ul (A și B).
Ca și implementare, am alocat memorie pentru vectorul rezultat (C), pentru vectorii transpuși a lui A și B (At și Bt), cât și pentru 3 variabile temporare în care am făcut operațiile de înmulțire și adunare pe rând (At * B în temp1, B * A în temp2 după care adunarea celor două în temp3). La final am înmulțit toată paranteza cu adunarea (At×B+B×A) cu Bt și am adăugat rezultatul în C.

### solver_opt.c
Aici am folosit același algoritm ca la neopt, doar că am adăugat optimizări pentru eficiența programului. Principalele optimizări includ utilizarea register pentru variabilele locale care sunt accesate frecvent, utilizarea pointerilor pentru a evita recalcularea adreselor în bucle, și optimizarea accesului la memorie pentru a beneficia de cache-ul procesorului. Aceste schimbări pot îmbunătățesc semnificativ performanța, mai ales pentru matrice de dimensiuni mari (aici fiind toate liniile matricei, concatenate intr-un vector de dimensiune N*N).

### solver_blas.c
Pe baza algoritmului neoptimizat, am încercat să îmbunătățesc operațiile folosind diferite funcții de blas cum ar fi: cblas_dcopy, cblas_dtrmm, cblas_dgemm.
Pentru implementare mi-am făcut 2 copii ale vectorului B, deoarece:
```c
cblas_dtrmm(CblasRowMajor, CblasLeft, CblasUpper, CblasTrans, CblasNonUnit, N, N, 1.0, A, N, B, N)
```
aici, rezultatul se salvează în B, deci vectorul inițial B este pierdut.
Astfel, pentru a putea face toate operațiile din expresia mea, am folosit și 2 copii ale lui B.
```c
cblas_dtrmm(CblasRowMajor, CblasLeft, CblasUpper, CblasTrans, CblasNonUnit, N, N, 1.0, A, N, B, N)
```
Această funcție înmulțește transpusul matricei triunghiulare superioare 𝐴 cu 𝐵 și stochează rezultatul în 𝐵.
```c
cblas_dtrmm(CblasRowMajor, CblasRight, CblasUpper, CblasNoTrans, CblasNonUnit, N, N, 1.0, A, N, B_copy, N)
```
Această funcție înmulțește matricea 𝐵 cu 𝐴 și stochează rezultatul în B_copy.
```c
cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasTrans, N, N, N, 1.0, temp, N, B_copy2, N, 0.0, C, N);
```
Această funcție înmulțește matricea temp (care este suma dintre B_copy și  𝐵 => (At * B) + (B * A)) cu transpusa lui B_copy2 și stochează rezultatul în 𝐶.

În concluzie, codul din solver_blas.c este optimizat folosind funcțiile BLAS, care sunt mult mai eficiente decât implementările manuale din neopt.c și opt.c. Funcțiile BLAS sunt specializate pentru a executa operații de algebra liniară foarte rapid, profitând de optimizările la nivel de hardware. Astfel, utilizarea BLAS duce la un cod mai performant și mai simplu.

#### cachegrind
##### I refs
* tema3_blas: 253,376,569
* tema3_neopt: 5,931,346,831
* tema3_opt_m: 1,995,348,393
Referințele de instrucțiuni mai mari indică mai multe instrucțiuni executate. Versiunea neoptimizată (tema3_neopt) a executat semnificativ mai multe instrucțiuni decât versiunile optimizate.
##### D refs
* tema3_blas: 100,958,559 (91,453,972 citiri + 9,504,587 scrieri)
* tema3_neopt: 2,968,114,428 (2,835,608,197 citiri + 132,506,231 scrieri)
* tema3_opt_m: 465,784,926 (461,441,119 citiri + 4,343,807 scrieri)
Similar cu referințele de instrucțiuni, versiunea neoptimizată a avut mult mai multe accesări de date, în special citiri.
##### I1 misses & LLi misses
Toate versiunile prezintă rateuri minime în cache-ul de instrucțiuni, sugerând o bună localitate spațială în accesarea instrucțiunilor.
##### D1 misses & LLd misses
* tema3_blas: Rateurile D1 sunt semnificative, dar mai mici decât în celelalte versiuni, indicând o performanță mai bună a cache-ului de date.
* tema3_neopt: Foarte multe rateuri D1 (112,542,528), dar rateuri relativ mici LLd (153,274), indicând că multe rateuri de nivel 1 sunt rezolvate la niveluri mai înalte de cache.
* tema3_opt_m: De asemenea, multe rateuri D1, dar arată o reducere eficientă a rateurilor LLd pentru citiri, indicând o localitate sau prefetching îmbunătățit.
##### Branches
* Consistente între versiunile optimizate și neoptimizate, deoarece reflectă structura fluxului de control.
##### Mispredicts
* Rata de predicții greșite este ușor mai mare în versiunea optimizată. Aceasta se poate datora unei structuri de control mai complexe, care poate fi mai dificil de gestionat pentru predictorul de ramificații. Totuși, impactul general asupra performanței din cauza predicțiilor greșite este probabil minim comparativ cu câștigurile din reducerea rateurilor cache.

#### Efectele optimizărilor manuale în solver_opt.c
* Reducerea Numărului de Instrucțiuni
  * Are mult mai puține referințe de instrucțiuni comparativ cu versiunea neoptimizată, acest lucru indicând faptul că optimizările manuale au redus efectiv numărul de instrucțiuni executate
* Îmbunătățirea utilizării cache-ului de date:
  * Deși are un număr mare de rateuri în cache-ul de date de nivel 1, are relativ puține rateuri în cache-ul de nivel ultim comparativ cu versiunea neoptimizată, indicând că codul optimizat accesează datele mai eficient
* Predicția ramificațiilor
  * Ratele de predicții greșite sunt ușor mai mari în versiunea optimizată. Acest lucru poate fi datorat faptului că optimizarea face uneori fluxul de control mai complex, ceea ce poate fi mai dificil de gestionat pentru predictorul de ramificații. Totuși, impactul general asupra performanței din cauza predicțiilor greșite este probabil minim comparativ cu câștigurile din reducerea rateurilor cache și a referințelor de instrucțiuni și date
* Câștiguri generale de performanță
  * Reducerea semnificativă a referințelor de instrucțiuni și date, împreună cu îmbunătățirea comportamentului cache-ului, indică faptul că optimizările manuale au fost eficiente. Acest lucru ar duce la timpi de execuție mai rapizi și o utilizare mai bună a resurselor CPU

În concluzie, optimizările manuale aplicate în solver_opt.c au dus la un program mai eficient cu mai puține instrucțiuni executate și o performanță mai bună a cache-ului, rezultând într-o îmbunătățire generală a performanței.