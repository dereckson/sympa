<!-- RCS Identication ; $Revision$ ; $Date$ -->

  [IF status=auth]
      You requested unsubscription from list [list]. <BR>To confirm
      your request, please click the button bellow :<BR>
	<BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_signoff" VALUE="I unsubscribe from list [list]">
	</FORM>

  [ELSIF not_subscriber]

      Usted no est� subscrito a la lista [list] con el E-mail [email].
      <BR><BR>
      Puede ser que est� subscrito con otra direcci�n.
      Por favor, contacte con el propietario de la lista para que le ayude con la anulaci�n:
      <A HREF="mailto:[list]-request@[conf->host]">[list]-request@[conf->host]</A>
      
  [ELSIF init_passwd]
    	Usted ha solicitado la anulaci�n de sus subscripci�n de la lista [list]. 
	<BR><BR>
	Para confirmar su identidad y evitar que alguien le anula la subscripci�n sin su permiso, un mensaje con una URL se le enviar�. <br><br>

	Compruebe los mensajes nuevos en su correo y utilice la contrase�a que Sympa le envia.
   Dicha contrase�a confirmar� su anulaci�n a la lista [list].
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="--DARK_COLOR--"><B>Direcci�n E-mail </B> </FONT>[email]<BR>
            <FONT COLOR="--DARK_COLOR--"><B>Contrase�a</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="Anula subscripci�n">
        </FORM>

      	Esta contrase�a, asociada con su E-mail, le permitir� acceder a su entorno WWSympa.

  [ELSIF ! email]
      Por favor, entre su E-mail para la anulaci�n de su subscripci�n a la lista [list].

      <FORM ACTION="[path_cgi]" METHOD=POST>
          <B>Su E-mail:</B> 
          <INPUT NAME="email"><BR>
          <INPUT TYPE="hidden" NAME="action" VALUE="sigrequest">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
         </FORM>


  [ELSE]

	Para confirmar la anulaci�n de su subscripci�n a la lista [list], entre la siguiente contrase�a:

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="--DARK_COLOR--"><B>E-mail </B> </FONT>[email]<BR>
            <FONT COLOR="--DARK_COLOR--"><B>Contrase�a</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="Anula subscripci�n">

<BR><BR>
<I>Si olvid� su contrase�a o no tiene ninguna de este servidor:</I>  <INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Enviarme mi contrase�a">

         </FORM>

  [ENDIF]      

