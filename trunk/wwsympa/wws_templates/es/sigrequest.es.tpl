<!-- RCS Identication ; $Revision$ ; $Date$ -->

  [IF status=auth]
      Ha solicitado la baja de la lista [list]. <BR>Para confirmar su
      petici�n pulse por favor el bot�n siguiente:<BR>
	<BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_signoff" VALUE="Me doy de baja de la lista [list]">
	</FORM>

  [ELSIF not_subscriber]

      Usted no est� suscrito a la lista [list] con el E-mail [email].
      <BR><BR>
      Puede ser que est� suscrito con otra direcci�n.
      Por favor, contacte con el propietario de la lista para que le ayude con la anulaci�n:
      <A HREF="mailto:[list]-request@[conf->host]">[list]-request@[conf->host]</A>
      
  [ELSIF init_passwd]
    	Usted ha solicitado la anulaci�n de sus suscripci�n de la lista [list]. 
	<BR><BR>
	Para confirmar su identidad y evitar que alguien le anula la suscripci�n sin su permiso, un mensaje con una URL se le enviar�. <br><br>

	Compruebe los mensajes nuevos en su correo y utilice la contrase�a que Sympa le envia.
   Dicha contrase�a confirmar� su anulaci�n a la lista [list].
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>Direcci�n E-mail </B> </FONT>[email]<BR>
            <FONT COLOR="[dark_color]"><B>Contrase�a</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="Anula suscripci�n">
        </FORM>

      	Esta contrase�a, asociada con su E-mail, le permitir� acceder a su entorno WWSympa.

  [ELSIF ! email]
      Por favor, introduzca su E-mail para darse de baja de la lista [list].

      <FORM ACTION="[path_cgi]" METHOD=POST>
          <B>Su E-mail:</B> 
          <INPUT NAME="email"><BR>
          <INPUT TYPE="hidden" NAME="action" VALUE="sigrequest">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="submit" NAME="action_sigrequest" VALUE="Anula suscripci�n">
         </FORM>

  [ELSE]

	Para confirmar la anulaci�n de su suscripci�n a la lista [list], digite la siguiente contrase�a:

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>E-mail </B> </FONT>[email]<BR>
            <FONT COLOR="[dark_color]"><B>Contrase�a</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="Anula suscripci�n">

<BR><BR>
<I>Si olvid� su contrase�a o no tiene ninguna para este servidor:</I>  <INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Enviarme mi contrase�a">

         </FORM>

  [ENDIF]      

