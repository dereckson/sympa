
  [IF status=auth]

	Usted solicit� una suscripci�n a la lista [list]. <BR>
	Pulse el siguiente bot�n para confirmarla: <br>
	<BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_subscribe" VALUE="Me suscribo a la lista [list]">
	</FORM>


  [ELSIF status=notauth_passwordsent]

	Usted solicit� una suscripci�n a la lista [list]. 
	<BR><BR>
 Para confirmar su identidad y evitar que alguien le suscriba sin su permiso, un mensaje con una contrase�a se le enviar� en breve. <br><br>

Compruebe los mensajes nuevos en su correo y utilice la contrase�a que Sympa le envia en el siguiente formulario. Dicha contrase�a confirmar� su suscripci�n a la lista [list].

        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>e-mail address</B> </FONT>[email]<BR>
	  <FONT COLOR="[dark_color]"><B>password</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_subscribe" VALUE="Suscribirse">
        </FORM>

  Esta contrase�a, asociada con su E-mail, le permitir� acceder a su entorno WWSympa.


  [ELSIF status=notauth_noemail]

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>Su E-mail</B> 
	  <INPUT  NAME="email" SIZE="30"><BR>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="action" VALUE="subrequest">
	  <INPUT TYPE="submit" NAME="action_subrequest" VALUE="Aceptar">
         </FORM>


  [ELSIF status=notauth]

 	Para confirmar su suscripci�n a la lista [list], entre su contrase�a en el sgte. formulario:

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>E-mail</B> </FONT>[email]<BR>
            <FONT COLOR="[dark_color]"><B>Contrase�a</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_subscribe" VALUE="Suscribirse">
	<INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Mi contrase�a?">
         </FORM>

  [ELSIF status=notauth_subscriber]

	<FONT COLOR="[dark_color]"><B>Usted ya es suscriptor de la lista [list].
	</FONT>
	<BR><BR>


	[PARSE '--ETCBINDIR--/wws_templates/loginbanner.es.tpl']

  [ENDIF]      



