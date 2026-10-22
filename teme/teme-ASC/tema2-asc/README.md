331CA - Mihai Daniel Soare
Arhitectura Sistemelor de Calcul

Tema 2

PS: urasc literele mari deci n-o sa le folosesc prea mult

November 2022
-------------
---------------------------------------------------------------------------------------------------

-> scopul temei este analizarea calculului pe matrici pornind de la o ecuatie gasind un rezultat,
folosind diferite implementari unele mai optimizate decat celelalte.

Implementari:
------------

``blas``

- am folosit exclusiv functii din biblioteca blas, m-am uitat pe documentatie si am cautat
cele mai usor de folosit functii din biblioteca, am ajuns la 2: ``DTRMM`` si ``DGEMM``.

- avand la dispozitia functia ``DTRMM`` (inmultire matrice triangulare) am apelat-o de doua ori
pentru inmultirea lui A * B si dupa a rezultatului cu A transpusa.

- apoi avand rezultatul partii din stanga, am apelat functia ``DGEMM`` (inmultire de matrice), care
are ca scop urmatorul calcul: alfa * A * B + beta * C, am privit rezultatul anterior ca C in
aceasta ecuatie, iar A si B vor fi inlocuite cu B transpus din ecuatia pe care vrem s-o calculam.

- este destul de directa implementarea, nu am nimic mai mult de comentat.

- ca timp este clar cea mai rapida implementare a mea, chiar mai rapida decat cea optimizata
(fara flag-uri)

``neopt``

- am folosit o implementare cat mai neoptimizata, am luat ecuatia in ordinea operatiilor si am facut
fiecare pas din ecuatie
- am creat buffere auxiliare unde era nevoie si dezalocat la gasirea rezultatului

``opt``

- luat implementarea neoptimizata si am inceput sa trec la optimizari:
- primul pas a fost retinerea variabilelor precum i, j, k in registrii
- apoi in loc sa modific direct vectorul la fiecare inmultire intre matrici, am salvat valoarea
auxiliara, iar apoi am adaugat-o in vector
- pentru ultimul for am salvat liniile care erau apelate de mai multe ori si am folosit pointeri
pentru a aduna la aceste valori
- de asemenea, am facut acelasi lucru pentru matricea rezultat
- cu toate aceste optimizari am ajuns constant la un timp intre 9 si 12 secunde pe partitia nehalem.
- la final am dezalocat vectorii auxiliari.



``cachegrind``

- in acest director se afla cele trei fisiere de la rularea lui valgrind cu modul cachegrind.
- in urma acestor fisiere se pot face urmatoarele observatii:

-> I refs: `blas` are cele mai putine referinte la Instrunction Cache, urmat de varianta optimizata
care are de 10 ori mai multe instrunction fetch, iar cea neoptimizata avand de 3 ori mai multe
decat cea optimizata. 

Neavand indexare prin indici a vectorului, in varianta optimizata avem acele de 3 ori mai putine
IC-uri.

Insa, se fac cele mai multe miss-uri la varianta blas, avand o rata de 0.01% de I1 miss, 
asta inseamna ca desi sunt mult mai putine instruction fetch-uri, rata este mult
mai mare de miss.

-> D refs: `blas` are cele mai putin referinte la date cat si cel mai mic numar de data misses,
urmatoarea fiind varianta optimizata si cea neoptimizata.
Acest outcome rezulta din accesul datelor, realizandu-se mult mai putine accese la date pentru
varianta optimizata datorita folosirea variabilelor stocate in registre.

-> Branches:: numarul de branches este similar intre varianta optimizata si neoptimizata din
cauza similaritatilor din structura celor doua, iar blas are un numar mult mai mic de branch-uri.

-> `blas` iese invingator in majoritatea cazurilor mai putin cand vine vorba de instrunction misses
avand un numar foarte ridicat pentru cat de putine apeluri se fac.


``analiza comparativa``

-> am rulat 5 teste cu cele 3 solutii (blas, neopt, opt_m):
N = {200, 400, 800, 1200, 1600}

-> Pentru toate cele 3 solutii, se pastreaza o crestere a timpilor iar ordinea
timpilor intre cele 3 solutii ramane aceeasi (t_blas << t_opt << t_neopt).

[Imgur](https://imgur.com/7QScqEB)

-> pentru varianta blas, 

---------------------------------------------------------------------------------------------------



