<!-- RCS Identication ; $Revision$ ; $Date$ -->


      Ha elfelejtetted a jelszavadat, vagy ezen a g�pen m�g nincsen,<br>
      akkor most emailben lek�rheted:

      <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="referer" VALUE="[referer]">
	  <INPUT TYPE="hidden" NAME="action" VALUE="sendpasswd">
  	  <INPUT TYPE="hidden" NAME="nomenu" VALUE="[nomenu]">

        <B>Email c�med</B>:<BR>
        [IF email]
	  [email]
          <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	[ELSE]
	  <INPUT TYPE="text" NAME="email" SIZE="20">
	[ENDIF]
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="K�ldd el a jelszavamat">
      </FORM>
