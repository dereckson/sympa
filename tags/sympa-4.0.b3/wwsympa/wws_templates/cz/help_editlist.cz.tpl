<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH p IN param]
<A NAME="[p->NAME]">
<B>[p->title]</B> ([p->NAME]):
<DL>
<DD>
[IF p->NAME=add]
  Opr�vn�n� pro p�id�n� (p��kaz ADD) �lena do konference
[ELSIF p->NAME=anonymous_sender]
  Pro skryt� emailov� adresy odes�latele p�ed distribuc� zpr�vy. Tato adresa
  je nahrazena poskytnutou adresou.
[ELSIF p->NAME=archive]
  Opr�vn�n� ��st arch�vy zpr�v a frekvenci archivov�n�  
[ELSIF p->NAME=owner]
  Vlastn�ci spravuj� �leny konference. Mohou si prohl�et seznam �len�, p�id�vat
  nebo mazat adresy ze seznamu. Pokud jste opr�vn�n�m spr�vcem konference,
  m��ete ur�it jin� vlastn�ky konference.

  Privilegovan� vlastn�ci mohou upravovat v�ce parametr� ne� jin� vlastn�ci. Pro
  konferenci m��e b�t pouze jeden prvilogovan� vlastn�k, jeho adresa se 
  ned� m�nit z webu.
[ELSIF p->NAME=editor]
Edito�i jsou zodpov�dn� za moderov�n� zpr�v. Pokud je konference moderovan�,
zpr�vy poslan� do konference jsou nej��v poslan� editor�m, kte�� rozhodnou,
jestli se zpr�va roze�le nebo odm�tne. <BR>
FYI: Ur�en� editor� nenastav� konferenci jako moderovanou; mus�te zm�nit 
parametr "send".<BR>
FYI: Pokud je konference moderovan�, prvn� editor, kter� potvrd� 
nebo odm�tne zpr�vu rozhodne za ostatn� editory. Pokud se nikdo nerozhodne,
zprava z�stane ve front� nemoderovan�ch zpr�v.
[ELSE]
  Bez koment��e
[ENDIF]

</DL>
[END]

