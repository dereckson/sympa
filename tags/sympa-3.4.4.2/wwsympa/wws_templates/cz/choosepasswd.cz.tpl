<!-- RCS Identication ; $Revision$ ; $Date$ -->

Pro WWW rozhran� si mus�te zvolit heslo. Toto heslo budete prot�ebovat
pro p��stup do vyhrazen�ch oblast�.

<FORM ACTION="[path_cgi]" METHOD=POST>
<INPUT TYPE="hidden" NAME="previous_action" VALUE="[previous_action]">
<INPUT TYPE="hidden" NAME="previous_list" VALUE="[previous_list]">

[IF init_passwd]
  <INPUT TYPE="hidden" NAME="passwd" VALUE="[user->password]">
[ELSE]
  <FONT COLOR="[dark_color]">Sou�asn� heslo : </FONT>
  <INPUT TYPE="password" NAME="passwd" SIZE=15>
[ENDIF]

<BR><BR><FONT COLOR="[dark_color]">Nov� heslo : </FONT>
<INPUT TYPE="password" NAME="newpasswd1" SIZE=15>
<BR><BR><FONT COLOR="[dark_color]">Nov� heslo znovu : </FONT>
<INPUT TYPE="password" NAME="newpasswd2" SIZE=15>
<BR><BR><INPUT TYPE="submit" NAME="action_setpasswd" VALUE="Odeslat">

</FORM>