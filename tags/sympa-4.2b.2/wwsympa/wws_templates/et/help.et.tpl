<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF help_topic]
 [PARSE help_template]

[ELSE]
<BR>
See WWSympa v�imaldab kasutada listserverit 
<B>[conf->email]@[conf->host]</B>.
<BR><BR>
Funktsioonid, mida saab kasutada ka eposti teel, on kasutajaliidese
�laosas. Kasutada on j�rgnevad funktsioonid:

<UL>
<LI><A HREF="[path_cgi]/pref">Eelistused</A>: kasutaja eelistused. Seda saavad kasutada ainult sisse loginud kasutajad.

<LI><A HREF="[path_cgi]/lists">Avalikud listid</A>: Avalike listide nimekiri

<LI><A HREF="[path_cgi]/which">Sinu listid</A>: Sinu listid, milles oled kas omanik v�i lihtliige.

<LI><A HREF="[path_cgi]/loginrequest">Logi sisse</A> / <A HREF="[path_cgi]/logout">Lahku</A>: Sympasse sisse logimine/Sympast lahkumine.
</UL>

<H2>Sisse logimine</H2>

[IF auth=classic]
Kui (<A HREF="[path_cgi]/loginrequest">logid sisse</A>), siis sisesta kasutajanimeks 
oma eposti aadress ning parooliks sellega seotud parool.
<BR><BR>
Kui oled sisse loginud, seatakse teie brauserisse <I>k�psis</I>, milles
on info, mis muudab teie �henduse WWSympaga p�sivaks. Selle <I>k�psise</I>
eluiga on seadistatav <A HREF="[path_cgi]/pref">eelistustest</A>.

<BR><BR>
[ENDIF]

Sa saad lahkuda WWSympast (see t�hendab <I>k�psise</I> kustutada) igal ajal
kasutades <A HREF="[path_cgi]/logout">Lahku</A> nuppu.

<H5>Probleemid sisse logimisel</H5>

<I>Ma ei ole �hegi listi liige. </I><BR>
J�relikult ei ole sa ka Sympa andmebaasis ja ei saa issse logida. 
Peale suvalise listiga liitumist annab WWSympa sulle esialgse parooli.
<BR><BR>

<I>Ma olen listi liige kuid mul ei ole parooli</I><BR>
Saad endale parooli siit: 
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>
<BR><BR>

<I>Olen oma parooli unustanud</I><BR>

WWSympa saab sulle su parooli uuesti saata:
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>

<P>

Listserveri administraatoriga saab �hendust siit: <A HREF="mailto:listmaster@[conf->host]">listmaster@[conf->host]</A>
[ENDIF]













