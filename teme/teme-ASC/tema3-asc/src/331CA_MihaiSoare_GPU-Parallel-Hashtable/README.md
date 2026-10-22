331CA - Mihai Daniel Soare
Arhitectura sistemelor de calcul

Assignment 3 - GPU Hashtable Paralel

May - June 2023
---------------

---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------

``gpu_hashtable.cu``

- contine clasa GpuHashTable care reprezinta implementarea mea de un hashtable
paralel.

- acesta contine urmatoarele campuri:

-> *keys - reprezinta un array de chei care vor fi stocate atat pe CPU cat
si pe GPU

-> *values - reprezinta un array de valori care vor fi stocate atat pe CPU cat si pe GPU

-> hSize - reprezinta numarul de perechi <cheie, valoare> inserate in hashtable

-> fullSize - reprezinta numarul total de perechi <cheie, valoare> care pot
fi inserate in hashtable

---------------------------------------------------------------------------------------------------

Clasa are urmatoarele metode:

A. ``reshape`` 

-> folosita pentru a crea 2 array noi de size-ul dorit pentru perechi
<cheie, valoare>, fiind luate cheile din fostele array-uri de dimensiune veche
in cele noi.

acest lucru se realizeaza cu functia kernel care este rulata pe fiecare gpu, in care:

-> se extrage indexul thread-ului

-> se hashuieste cheia respectiva thread-ului respectiv

-> apoi se folosete % fullSize pentru aflarea indexului cheii

-> se parcurge incepand cu indexul aflat pe baza hash % fullSize in rotatie circulara 
pana cand  se gaseste cheia veche, daca nu se gaseste se introduce in prima pozitie libera.

ATENTIE: acest lucru este valid, doar pentru ca se foloseste mereu acelasi drum,
deci daca valoarea cheii n-a fost gasita pana la primul spatiu disponibil,
inseamna ca nu a fost inserata inca in hashtable.

Modul de parcurgere:

hashIdx -> fullSize

0 -> hashIdx - 1

ex:     0 .... hashIdx .... fullSize

Step1:           ->               ->

Step2:  ->     ->

---------------------------------------------------------------------------------------------------

B. ``insertBatch``

-> se face impartirea pe thread-uri de GPU in functie de size-uri

-> se adauga cate valori vor fi inserate

-> se verifica daca exista destul loc in hashtable

-> se copiaza perechile <cheie, valoare> de pe cpu pe gpu

-> se apeleaza kernelul insert keys mentionat anterior

-> se eliberea memoria auxiliara

C. ``getBatch``

-> se face impartirea pe thread-uri de GPU in functie de size-uri

-> se aloca memorie pe gpu pentru chei si valori

-> se copiaza cheile pe GPU

-> se apeleaza functia kernel GetKeys care va fi rulata pe fiecare thread GPU.

este foarte similara cu ce am mentionat anterior la InsertKeys, insa:

se cauta cheia care este aceeasi cu cheia verificata pe thread si daca este gasita in hashtable, 
va fi extrasa valoarea acesteia si returnata catre client.

---------------------------------------------------------------------------------------------------

Discutie bazata pe rezultate:
----------------------------

pe partea de insert, cu cat facem reshape cu o dimensiune mai mare, cu atat va dura
mai mult inserarea in hashtable, mai ales ca se fac niste operatii atomice pentru 
verificarea cheilor.

-> loadFactor va ramane constant deoarece nu raman
date in afara hashtable-ului

cand vine vorba de get:
viteza ar trebui sa fie in mare parte constanta si cu
mici fluctuatii.

-> loadFactorul va scade, deoarece memoria nu este eliberata in test_map, si astfel va 
ramane memorie neeliberata, iar loadFactorul scade.

