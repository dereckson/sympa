From: [conf->email]@[conf->host]
Subject: Bem-vindo � lista [list->name]
Mime-version: 1.0
Content-Type: multipart/alternative; boundary="===Sympa==="

--===Sympa===
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

Bem-vindo � lista [list->name]@[list->host].
Voc� foi subscrito com o e-mail [user->email]
[IF user->password]
E clave : [user->password]
[ENDIF]

[PARSE 'info']

P�r mais informa��o acerca de esta lista :
[conf->wwsympa_url]/info/[list->name]

--===Sympa===
Content-Type: text/html; charset=iso-8859-1
Content-transfer-encoding: 8bit

<HTML>
<HEAD>
<TITLE>Bem-vindo � lista [list->name]@[list->host]</title>
<BODY  BGCOLOR=#ffffff>

<B>Bem-vindo � lista [list->name]@[list->host]. </B><BR>
Voc� foi subscrito com o e-mail [user->email]
[IF user->password]
<BR>
E clave : [user->password]
[ENDIF]
<BR><BR>
<PRE>
[PARSE 'info']
</PRE>

<HR>
P�r mais informa��o acerca de esta lista :
<A HREF="[conf->wwsympa_url]/info/[list->name]">[conf->wwsympa_url]/info/[list->name]</A>

</BODY></HTML>)
--===Sympa===--
