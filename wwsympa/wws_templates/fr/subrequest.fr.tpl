<!-- RCS Identication ; $Revision$ ; $Date$ -->

  [IF status=auth]

        Vous avez demand� un abonnement � la liste  [list], merci de confirmer
        cette demande :<BR>
	<BR>
	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_subscribe" VALUE="Je m'abonne � [list]">
	</FORM>


  [ELSIF status=notauth_passwordsent]

	Vous avez demand� un abonnement � la liste  [list]<BR>
        Pour valider votre identit� et emp�cher un tiers de vous abonner �
        votre insu, un message vous a �t� post�. Il contient votre mot de 
	passe et vous permettra de valider cet abonnement. <BR><BR>

        Surveillez votre boite aux lettres et fournissez ce mot de passe
        ici d�s sa r�ception.<BR>
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="--DARK_COLOR--"><B>adresse de messagerie</B> </FONT>[email]<BR>
	  <FONT COLOR="--DARK_COLOR--"><B>mot de passe </B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_subscribe" VALUE="Abonnement">
        </FORM>

      	Ce mot de passe vous permet en outre de personnaliser votre environnement de liste.

  [ELSIF status=notauth_noemail]

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="--DARK_COLOR--"><B>Votre adresse de messagerie :</B> 
	  <INPUT  NAME="email" SIZE="30"><BR>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="action" VALUE="subrequest">
	  <INPUT TYPE="submit" NAME="action_subrequest" VALUE="valider">
         </FORM>


  [ELSIF status=notauth]

	Pour valider votre demande d'abonnement � [list], merci de rentrer
        votre mot de passe :

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="--DARK_COLOR--"><B>Adresse de messagerie</B> </FONT>[email]<BR>
            <FONT COLOR="--DARK_COLOR--"><B>mot de passe</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_subscribe" VALUE="Abonnement">
	<BR>Si vous avez oubli� votre mot de passe : 
	<INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Envoyez-moi mon mot de passe">
         </FORM>

  [ELSIF status=notauth_subscriber]

	<FONT COLOR="--DARK_COLOR--"><B>Vous �tes d�j� abonn� � la liste [list].
	</FONT>
	<BR><BR>


	[PARSE '--ETCBINDIR--/wws_templates/loginbanner.fr.tpl']

  [ENDIF]      



