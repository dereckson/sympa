  [IF status=auth]

        Vous avez demand� � vous d�sabonner de la liste  [list], merci de confirmer
        cette demande :<BR>
	<BR>
	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_signoff" VALUE="Je me d�sabonne de [list]">
	</FORM>

  [ELSIF not_subscriber]
      Vous n'�tes pas abonn� � la liste [list], en tout cas pas avec l'adresse [email].
      <BR><BR>
	Peut �tre �tes vous abonn� avec une autre adresse ? Dans ce cas connectez
        vous avec celle-ci. En cas de difficult�s contactez le propri�taire de la
        liste : <A HREF="mailto:[list]-request@[conf->host]">[list]-request@[conf->host]</A>
      
  [ELSIF init_passwd]
	Vous avez demand� un d�sabonnement de la liste [list]. 
	<BR><BR>
	Pour confirmer votre identit� et emp�cher un tier de vos d�sabonner, le
        serveur vient de vous poster un message avec un mot de passe
        de confirmation � l'adresse [email].

	Relevez votre boite aux lettres  pour renseigner votre mot de passe. Cela confirmera
        votre demande de d�sabonnement de [list].
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="--DARK_COLOR--"><B>e-mail address</B> </FONT>[email]<BR>
            <FONT COLOR="--DARK_COLOR--"><B>mot de passe</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="D�sabonnement">
        </FORM>

      	Ce mot de passe associ� � votre adresse [email] permettra d'acc�der compl�tement
        � votre environement personnel.

  [ELSIF ! email]
      Indiquez votre adresse pour votre demande de d�sabonnement de
      la liste [list].

      <FORM ACTION="[path_cgi]" METHOD=POST>
          <B>Votre addresse :</B> 
          <INPUT NAME="email"><BR>
          <INPUT TYPE="hidden" NAME="action" VALUE="sigrequest">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
         </FORM>


  [ELSE]

	Pour confirmer votre demande de d�sabonnement de la liste [list],
        merci de renseigner votre mot de passe ci-dessous :

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="--DARK_COLOR--"><B>e-mail address</B> </FONT>[email]<BR>
            <FONT COLOR="--DARK_COLOR--"><B>mot de passe</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="d�sabonnement">
<BR><BR>

<I>Si vous n'avez jamais eu de mot de passe ou si vous l'avez oubli� :</I>
<INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="envoyez moi mon mot de passe">
         </FORM>


  [ENDIF]      



