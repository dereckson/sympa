From: [conf->email]@[conf->host]
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
