<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF help_topic]
 [PARSE help_template]

[ELSE]
<BR>
WWSympa a <B>[conf->email]@[conf->host]</B> levelez�lista szerveren
t�rolt be�ll�t�said m�dos�t�s�hoz ny�jt el�r�st.
<BR><BR>
A m�veletek, a Sympa email parancsok megfelel�i, a felhaszn�l�i oldal
fels� r�sz�n �rhet�ek el. WWSympa fel�let�n kereszt�l a k�vetkez�
m�veletek v�gezhet�ek el:

<UL>
<LI><A HREF="[path_cgi]/pref">Be�ll�t�sok</A>: felhaszn�l� be�ll�t�sai. Csak a felhaszn�l� azonos�t�s�hoz sz�ks�ges.

<LI><A HREF="[path_cgi]/lists">Nyilv�nos list�k</A>: a szerveren m�k�d� nyilv�nos levelez�list�k sora.

<LI><A HREF="[path_cgi]/which">Feliratkoz�sod</A>: listatag vagy tulajdonos be�ll�t�sai.

<LI><A HREF="[path_cgi]/loginrequest">Bel�p�s</A> / <A HREF="[path_cgi]/logout">Kil�p�s</A> : Bel�p�s / Kil�p�s a WWSympa programb�l.
</UL>

<H2>Bel�p�s</H2>

Azonos�t�skor (<A HREF="[path_cgi]/loginrequest">Bel�p�s</A>) meg kell adnod az email c�medet �s jelszavadat.
<BR><BR>
Sikeres azonos�t�s ut�n a bejelentkez�si adatokat a WWSympa a 
kapcsolat folyam�n <i>s�ti</i>ben t�rolja. A <i>s�ti</i> �rv�nyess�gi
idej�t a <A HREF="[path_cgi]/pref">be�ll�t�sok</A> men�ben lehet
megadni. 

<BR><BR>
B�rmikor ki lehet l�pni (a <i>s�ti</i> t�rl�dik) a
<A HREF="[path_cgi]/logout">kil�p�s</A> men�vel.

<H5>Bejelentkez�sr�l</H5>

<I>Nem vagyok listatag </I><BR>
Teh�t a Sympa adatb�zis�ban nem vagy nyilv�ntartva, ez�rt nem tudsz bejelentkezni.
Ha lista tag vagy, akkor a WWSympa el k�ldheti a jelenlegi jelszavadat.
<BR><BR>

<I>Legal�bb egy lista tagja vagyok, de nincs jelszavam</I><BR>
Jelszavadat innen kaphatod meg: 
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>
<BR><BR>

<I>Elfelejtettem a jelszavamat</I><BR>

WWSympa eml�keztet��l el k�ldheti a jelszavadat:
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>

<P>

A rendszergazd�t itt �rheted el: <A HREF="mailto:listmaster@[conf->host]">listmaster@[conf->host]</A>
[ENDIF]













