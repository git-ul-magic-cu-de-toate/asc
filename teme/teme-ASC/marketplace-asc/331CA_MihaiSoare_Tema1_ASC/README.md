331CA - Mihai Daniel Soare
Arhitectura sistemelor de calcul

Assignment 2 - Producer - Consumer in Python

April 2023
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``marketplace.py``

- este clasa prin care atat consumerul cat si producerul vor apela diferite metode utile in
implementare, la care au acces prin intermediul marketplace-ului

- contine urmatoarele campuri:
    -> no_producers
    -> no_consumers
    -> carts - fiecare consumer va avea un cart disponibil la un moment dat
    -> count_products - un dictionar in care se retin cate produse au fost publicate catre
    marketplace de catre un producer
    -> producers_per_products - un dictionar in care se retin produsele si producerii care au
    publicat produsul disponibil si exista in marketplace in real time

__init__
-> constructor in care se initializeaza si campurile de logging necesare ulterior

__register_producer__
-> returneaza un id pentru un producer nou

__publish__
-> creeaza o intrare noua atat in dictionarul de count_products cat si in producers_per_products
pentru producerul care a creat un anumit produs

__new_cart__
-> returneaza un id pentru un consumer nou

__add_to_cart__
-> se adauga in cartul consumatorului produsul dorit, daca este disponibil in marketplace

__remove_from_cart__
-> sterge un produs din cosul consumatorului si retrimite fostului producatorul obiectul

__place_order__
-> sterge cosul actual al consumatorului si "primeste" o lista de produse

``producer.py``

__run__
-> metoda specifica unui thread care este apelata atunci cand se foloseste metoda .start(),
odata apelata va produce pana cand consumatorii nu vor mai avea nevoie de produse, diferite produse
dintr-o lista primita ca argument in testare.
-> se inregistreaza producatorul
-> se repeta urmatorii pasi:
    -> produc secvential obiecte de tip "idx" si se publica pe rand cu un timp intre
    fiecare produs de acelasi tip
    -> daca nu se pot adauga obiecte in marketplace, se reincearca ulterior dupa un timp
-> se foloseste un lock pe metoda de publish deoarece acest buffer este comun intre consumatori
si producatori

``consumer.py``

__run__
-> odata apelata va parcurge o lista de cosuri pe care doreste sa le parcurga
-> pentru fiecare cart exista 2 tipuri de comenzi: adaugarea produselor in lista / stergerea
lor din lista aka cos
-> implementarea e destul de straightforward se foloseste un lock pe metodele de adaugare
si sterge in cos deoarece folosesc un buffer comun intre consumer si produceri

``product.py``

-> am adaugat o noua data clasa pentru a pastra mai usor informatiile necesare (aka) cine a creat
un produs

``logging``
-> am afisat fiecare apel din marketplace, nu am putut adauga mai mult deoarece au inceput
sa pice teste random fara sa aiba legatura cu implementarea

``unittests``
-> am creat unit teste basic care sa verifice rezultatul metodelor din marketplace atat la
success cat si la failure