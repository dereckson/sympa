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

