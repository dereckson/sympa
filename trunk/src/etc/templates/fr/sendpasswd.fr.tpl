From: [conf->sympa]
Reply-to: [conf->request]
To: [newuser->email]
[IF action=subrequest]
Subject: [wwsconf->title] / abonnement � [list]
[ELSIF action=sigrequest]
Subject: [wwsconf->title] / d�sabonnement de [list]
[ELSE]
Subject: [wwsconf->title] / votre environnement
[ENDIF]
Content-Type: multipart/alternative;
  boundary="============ [list] ============--"
Content-Transfer-Encoding: 8bit

--============ [list] ============--
Content-Type: text/plain
Content-Transfer-Encoding: 8bit

[IF action=subrequest]
Vous avez demand� � vous abonner � la liste de diffusion [list].

Pour valider votre abonnement, vous devez fournir le mot de passe suivant

	mot de passe : [newuser->password]

[ELSIF action=sigrequest]
Vous avez demand� � vous d�sabonner de la liste de diffusion [list].

Pour vous d�sabonner, vous devez fournir le mot de passe suivant
	
	mot de passe : [newuser->password]

[ELSE]
Pour personnaliser votre environnement, vous devez vous identifier (login)

     votre adresse �lectronique : [newuser->email]
     votre mot de passe         : [newuser->password]

Changement de mot de passe
[base_url][path_cgi]/choosepasswd/[newuser->escaped_email]/[newuser->password]
[ENDIF]

[wwsconf->title] : [base_url][path_cgi] 

Aide sur Sympa : [base_url][path_cgi]/help

--============ [list] ============--
Content-Type: text/html
Content-Transfer-Encoding:  7bit

<HTML>
<HEAD>
</HEAD>
<BODY>

<TABLE WIDTH="100%" BORDER="0" cellpadding="2" cellspacing="0">
<TR><TD WIDTH="100%">&nbsp</TD>
<TD NOWRAP BGCOLOR="--LIGHT_COLOR--" ALIGN="right"><A HREF="[base_url][path_cgi]">Accueil</A> <B>|</B>
<A HREF="[base_url][path_cgi]/help">Aide</A></TD>
</TR>
<TR><TD COLSPAN="2" ALIGN="center" BGCOLOR="--SELECTED_COLOR--">
<FONT COLOR="--BG_COLOR--" SIZE="+2"><B>
[IF action=subrequest]
[wwsconf->title] / abonnement � [list]
[ELSIF action=sigrequest]
[wwsconf->title] / d�sabonnement de [list]
[ELSE]
[wwsconf->title] / votre environnement
[ENDIF]
</B></FONT>
</TD></TR>
<TR><TD COLSPAN="2" BGCOLOR="--BG_COLOR--">

<P>
<FORM ACTION="[base_url][path_cgi]" METHOD=POST>
<INPUT TYPE="hidden" NAME="email" VALUE="[newuser->email]">
<INPUT TYPE="hidden" NAME="passwd" VALUE="[newuser->password]">

[IF action=subrequest]
Vous avez demand� � vous abonner � la liste de diffusion [list].<BR>
Pour valider votre abonnement, choisissez un mot de passe qui, associ� � votre adresse �lectronique,
vous permettra de vous identifier sur le serveur de listes :<UL>

<INPUT TYPE="hidden" NAME="action" VALUE="subscribe">
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">

<LI>Adresse �lectronique : [newuser->email]
<LI>Mot de passe : <INPUT TYPE="password" NAME="newpasswd1" SIZE=15>
<LI>Confirmation mot de passe : <INPUT TYPE="password" NAME="newpasswd2" SIZE=15>
</UL>

<INPUT TYPE="submit" NAME="action_subscribe" VALUE="Abonnement � [list]">

[ELSIF action=sigrequest]
Vous avez demand� � vous d�sabonner de la liste de diffusion [list].<BR>
Pour vous d�sabonner, choisissez un mot de passe qui, associ� � votre adresse �lectronique,
vous permettra de vous identifier sur le serveur de listes : <UL>

<INPUT TYPE="hidden" NAME="action" VALUE="signoff">
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">

<LI>Adresse �lectronique : [newuser->email]
<LI>Mot de passe : <INPUT TYPE="password" NAME="newpasswd1" SIZE=15>
<LI>Confirmation mot de passe : <INPUT TYPE="password" NAME="newpasswd2" SIZE=15>

</UL>
<INPUT TYPE="submit" NAME="action_signoff" VALUE="D�sabonnement de [list]">

[ELSE]

<INPUT TYPE="hidden" NAME="action" VALUE="login">

Pour acc�der � votre environnement, vous devez vous identifier (login)<BR>
[IF init_passwd=1]

Choisissez pr�alablement un mot de passe qui, associ� � votre adresse �lectronique,
vous permettra de vous identifier sur le serveur de listes :<UL>
<LI>Adresse �lectronique : [newuser->email]
<LI>Mot de passe : <INPUT TYPE="password" NAME="newpasswd1" SIZE=15>
<LI>Confirmation mot de passe : <INPUT TYPE="password" NAME="newpasswd2" SIZE=15>
</UL>
[ELSE]
<UL>
<LI>Adresse �lectronique : <B>[newuser->email]</B>
<LI>Votre mot de passe   : <B>[newuser->password]</B>

</UL>
[ENDIF]

<INPUT TYPE="submit" NAME="action_login" VALUE="Login">

[ENDIF]
</FORM>

</TD></TR>
<TR><TD ALIGN="right"COLSPAN="2">
<I>Powered by <A HREF="http://listes.cru.fr/sympa">Sympa</A></I>
</TD></TR>
</TABLE>

</BODY>

</HTML>

--============ [list] ============----
