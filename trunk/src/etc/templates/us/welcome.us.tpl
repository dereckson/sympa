From: [conf->email]@[conf->host]
[IF  list->lang=fr]
Subject: Bienvenue sur la liste [list->name]
Mime-version: 1.0
Content-Type: text/html;
Content-transfer-encoding: 8bit

<HTML>
<HEAD>
<TITLE>Bienvenue dans la liste [list->name]@[list->host]</title>
<BODY  BGCOLOR=#ffffff>

<B>Bienvenue dans la liste [list->name]@[list->host].</B><BR> 
Votre adresse d'abonnement est  [user->email] 
[IF user->password] 
<BR>
Votre mot de passe : [user->password]
[ENDIF]
<BR><BR>
<PRE>
[PARSE 'info']
</PRE>

<HR>
Pour tout savoir sur cette liste :
<A HREF="[conf->wwsympa_url]/info/[list->name]">[conf->wwsympa_url]/info/[list->name]</A>


</BODY></HTML>

[ELSIF list->lang=es]
Subject: Bienvenido a la lista [list->name]
Mime-version: 1.0
Content-Type: text/html;
Content-transfer-encoding: 8bit

<HTML>
<HEAD>
<TITLE>Bienvenido a la lista [list->name]@[list->host]</title>
<BODY  BGCOLOR=#ffffff>

<B>Bienvenido a la lista [list->name]@[list->host]. </B><BR>
Usted ha sido subscrito con el e-mail [user->email]
[IF user->password]
<BR>
Y contrase�a : [user->password]
[ENDIF]
<BR><BR>
<PRE>
[PARSE 'info']
</PRE>

<HR>
Para m�s informaci�n acerca de esta lista :
<A HREF="[conf->wwsympa_url]/info/[list->name]">[conf->wwsympa_url]/info/[list->name]</A>

</BODY></HTML>

[ELSIF list->lang=it]
Subject: Benvenuto nella lista [list->name]
Mime-version: 1.0
Content-Type: text/html;
Content-transfer-encoding: 8bit

<HTML>
<HEAD>
<TITLE>Benvenuto nella lista [list->name]@[list->host]</title>
<BODY  BGCOLOR=#ffffff>

<b>Benvenuto nella lista [list->name]@[list->host].</b><BR>
Il suo indirizzo di iscrizione e' [user->email]
[IF user->password]
<BR>
La sua password : [user->password]
[ENDIF]
<BR><BR>
<PRE>
[PARSE 'info']
</PRE>

<hr>


</body></html>

[ELSIF list->lang=pl]
Subject: Witaj na li�cie [list->name]
Mime-version: 1.0
Content-Type: text/html;
Content-transfer-encoding: 8bit

<HTML>
<HEAD>
<TITLE>Benvenuto nella lista [list->name]@[list->host]</title>
<BODY  BGCOLOR=#ffffff>

<b>Witaj na li�cie [list->name]@[list->host].</b><BR>
Zosta�e� zapisany z adresem [user->email]
[IF user->password]
<BR>
Twoje has�o to: [user->password]
[ENDIF]
<BR><BR>
<PRE>
[PARSE 'info']
</PRE>
<HR>

Informacje o li�cie:
<A HREF="[conf->wwsympa_url]/info/[list->name]">[conf->wwsympa_url]/info/[list->name]</A>

</BODY></HTML>

[ELSIF list->lang=cz]
Subject: Vitejte v konferenci [list->name]
Mime-version: 1.0
Content-Type: multipart/alternative; boundary="===Sympa==="

--===Sympa===
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit


Dobr� den.

V�tejte v konferenci [list->name]@[list->host].
Jste p�ihl�en z adresy [user->email]
[IF user->password]
Va�e heslo je: [user->password]
[ENDIF]

[PARSE 'info']

Informace o konferenci:
[conf->wwsympa_url]/info/[list->name]

--===Sympa===
Content-Type: text/html; charset=iso-8859-2
Content-transfer-encoding: 8bit

<HTML>
<HEAD>
<TITLE>V�tejte v konferenci [list->name]@[list->host]</title>
<BODY  BGCOLOR=#ffffff>
Dobr� den.<p>
<b>V�tejte v konferenci [list->name]@[list->host].</b><BR>
Jste p�ihl�en z adresy [user->email]
[IF user->password]
<BR>
Va�e heslo je: [user->password]
[ENDIF]
<BR><BR>
<PRE>
[PARSE 'info']
</PRE>
<HR>

Informace o konferenci:
<A HREF="[conf->wwsympa_url]/info/[list->name]">[conf->wwsympa_url]/info/[list->name]</A>

</BODY></HTML>
--===Sympa===--
[ELSIF list->lang=de]
Subject: Willkommen auf der Mailing-Liste [list->name]
Content-Type: text/html


<HTML>
<HEAD>
<TITLE>Willkommen auf der Mailing-Liste [list->name]@[list->host]</title>
<BODY  BGCOLOR=#ffffff>

<B>Willkommen auf der Mailing-Liste [list->name]@[list->host]. </B><BR>
Sie sind mit der EMail-Adresse [user->email] registriert.
[IF user->password]
<BR> 
Ihr Passwort: [user->password].
[ENDIF]
<BR><BR>
<PRE>
[PARSE 'info']
</PRE>

<HR>
Weitere Informationen &uuml;ber die Liste:
<A HREF="[conf->wwsympa_url]/info/[list->name]">[conf->wwsympa_url]/info/[list->name]</A>
</BODY></HTML>

[ELSE]
Subject: Welcome in list [list->name]
Content-Type: text/html


<HTML>
<HEAD>
<TITLE>Welcome in list [list->name]@[list->host]</title>
<BODY  BGCOLOR=#ffffff>

<B>Welcome in list [list->name]@[list->host]. </B><BR>
Your subscrition email is [user->email] 
[IF user->password] 
<BR>
Your password : [user->password]. 
[ENDIF]
<BR><BR>
<PRE>
[PARSE 'info']
</PRE>

<HR>
Everything about this list :
<A HREF="[conf->wwsympa_url]/info/[list->name]">[conf->wwsympa_url]/info/[list->name]</A>


</BODY></HTML>
[ENDIF]

