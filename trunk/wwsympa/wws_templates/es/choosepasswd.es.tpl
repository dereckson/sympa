<!-- RCS Identication ; $Revision$ ; $Date$ -->

Usted necesita una contrase�a para su entorno de WWSympa.
Esta contrase�a le permitir� acceder a funciones especiales.

<FORM ACTION="[path_cgi]" METHOD=POST>
<INPUT TYPE="hidden" NAME="previous_action" VALUE="[previous_action]">
<INPUT TYPE="hidden" NAME="previous_list" VALUE="[previous_list]">

[IF init_passwd]
  <INPUT TYPE="hidden" NAME="passwd" VALUE="[user->password]">
[ELSE]
  <FONT COLOR="--DARK_COLOR--">Contrase�a actual: </FONT>
  <INPUT TYPE="password" NAME="passwd" SIZE=15>
[ENDIF]

<BR><BR><FONT COLOR="--DARK_COLOR--">Contrase�a nueva: </FONT>
<INPUT TYPE="password" NAME="newpasswd1" SIZE=15>
<BR><BR><FONT COLOR="--DARK_COLOR--">Contrase�a nueva (repetir): </FONT> 
<INPUT TYPE="password" NAME="newpasswd2" SIZE=15>
<BR><BR><INPUT TYPE="submit" NAME="action_setpasswd" VALUE="Aceptar">

</FORM>

