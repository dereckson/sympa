From: [conf->email]@[conf->host]
Subject: Bem-vindo � lista [list->name]
Mime-version: 1.0
Content-Type: text/html;
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

