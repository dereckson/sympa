<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH p IN param]
<A NAME="[p->NAME]">
<B>[p->title]</B> ([p->NAME]):
<DL>
<DD>
[IF p->NAME=add]
  Jog tag felirat�s�hoz (ADD parancs) a list�ra
[ELSIF p->NAME=anonymous_sender]
  Az �zenet eredeti felad�j�nak elrejt�se a lev�l list�n megjelen�sekor.
  A megadott email c�m ker�l a felad� hely�re.
[ELSIF p->NAME=archive]
  Jog a lev�l arch�vum olvas�s�hoz �s annak friss�t�s�hez.
[ELSIF p->NAME=owner]
  A tulajdonosok a listatagokat kezelhetik. Tagokat ellen�r�zhetnek, fel�rhatnak
  vagy t�r�lhetnek a list�n. Ha tulajdonosa vagy a list�nak, akkor �jabb gazd�kat
  is rendelhetsz a list�hoz.
  A tulajdonos kicsivel t�bb joggal rendelkezik, mint a t�bbi tag. Egyszerre csak
  egy tulajdonosa lehet a list�nak; email c�met weben kereszt�l nem lehet megv�ltoztatni.
[ELSIF p->NAME=editor]
A szerkeszt�k a megjelen� leveleket kezelik. Ha a levelez�lista moder�lt, akkor az �zenetek el�sz�r a szerkeszt�kh�z jutnak el, 
akik d�ntenek annak megjelen�s�r�l vagy t�rl�s�r�l. <BR>
BIZ: Szerkeszt�k megad�s�val m�g nem v�lik a lista moder�ltt�, ahhoz a
"send" param�tert is be kell �ll�tani.<BR>
BIZ: Ha a lista moder�lt, akkor a szerkeszt� aki legel�sz�r d�nt a lev�l
sors�r�l a t�bbi szerkeszt� nev�ben is d�nt. Am�g senki sem b�r�lja el a
levelet, add�g a moder�l�sra v�r� levelek k�z�tt marad.
[ELSE]
  Nincs megjegyz�s
[ENDIF]

</DL>
[END]
	