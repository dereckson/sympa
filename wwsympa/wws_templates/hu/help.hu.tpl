<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF help_topic]
 [PARSE help_template]

[ELSE]
<BR>
A WWSympa fel�let a <B>[conf->email]@[conf->host]</B> levelez�lista-szerveren
t�rolt be�ll�t�said m�dos�t�s�hoz ny�jt egyszer� el�r�st.
<BR><BR>
A m�veletek, a Sympa e-mail parancsok megfelel�i, a felhaszn�l�i oldal
fels� r�sz�n �rhet�ek el. A WWSympa fel�leten kereszt�l a k�vetkez�
m�veletek �rhet�k el:

<UL>
<LI><A HREF="[path_cgi]/pref">Be�ll�t�saim</A>: felhaszn�l� be�ll�t�sai. Csak a felhaszn�l� egyedi azonos�t�s�hoz sz�ks�ges.

<LI><A HREF="[path_cgi]/lists">Nyilv�nos list�k</A>: a szerveren m�k�d� nyilv�nos levelez�list�k sora.

<LI><A HREF="[path_cgi]/which">Feliratkoz�saim</A>: listatag vagy tulajdonos be�ll�t�sai.

<LI><A HREF="[path_cgi]/loginrequest">Bel�p�s</A> / <A HREF="[path_cgi]/logout">Kil�p�s</A> : Bel�p�s / Kil�p�s a WWSympa programb�l.
</UL>

<H2>Bel�p�s</H2>

[IF auth=classic]
Azonos�t�skor (<A HREF="[path_cgi]/loginrequest">Bel�p�s</A>) meg kell adnod az e-mail c�medet �s jelszavadat.
<BR><BR>
Sikeres azonos�t�s ut�n a bejelentkez�si adatokat a WWSympa a 
kapcsolat folyam�n <i>s�ti</i>ben t�rolja. A <i>s�ti</i> �rv�nyess�gi
idej�t a <A HREF="[path_cgi]/pref">be�ll�t�saim</A> men�ben lehet
megadni. 

<BR><BR>
[ENDIF]

A <A HREF="[path_cgi]/logout">Kil�p�s</A> men�vel b�rmikor ki lehet l�pni
a programb�l, ekkor az azonos�t�shoz haszn�lt <i>s�ti</i> t�rl�dik.

<H5>Bejelentkez�sr�l</H5>

<I>Nem vagyok listatag </I><BR>
Teh�t a Sympa adatb�zis�ban nem vagy nyilv�ntartva, ez�rt nem tudsz bejelentkezni.
Ha lista tag vagy, akkor a WWSympa k�r�sre elk�ldheti a jelenlegi jelszavadat,
hogy be tudj jelentkezni.
<BR><BR>

<I>Legal�bb egy lista tagja vagyok, de nincs jelszavam</I><BR>
A jelszavadat a k�vetkez� oldalon lek�rheted e-mailben: 
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>
<BR><BR>

<I>Elfelejtettem a jelszavamat</I><BR>

A WWSympa eml�keztet��l elk�ldheti a jelszavadat:
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>

<P>

A rendszergazd�t itt �rheted el: <A HREF="mailto:listmaster@[conf->host]">listmaster@[conf->host]</A>
[ENDIF]
