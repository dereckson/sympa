<!-- RCS Identication ; $Revision$ ; $Date$ -->

<BR>
[IF password_sent]
  Jelszavadat a(z) [init_email] email c�mre elk�ldt�k.<BR>
  A lev�l meg�rkez�se ut�n add meg lent a jelszavadat.
  <BR><BR>
[ENDIF]

[IF action=loginrequest]
 Be kell jelentkezned, hogy m�dos�tani tudd a be�ll�t�saidat vagy kiemelt
 m�veleteket (amelyekhez meg kell adnod az email c�medet) tudj v�gezni.
[ELSE]
 A legt�bb m�dos�t�shoz meg kell adnod az email c�medet. N�h�ny be�ll�t�s csak
 bizonyos szem�lyeknek �rhet� el.<BR>
 A szerveren t�rt�n� m�dos�t�sokhoz val�sz�n�leg el�bb azonos�tanod kell magadat.<BR>
[ENDIF]

    <FORM ACTION="[path_cgi]" METHOD=POST> 
        <INPUT TYPE="hidden" NAME="previous_action" VALUE="[previous_action]">
        <INPUT TYPE="hidden" NAME="previous_list" VALUE="[previous_list]">
	<INPUT TYPE="hidden" NAME="referer" VALUE="[referer]">
	<INPUT TYPE="hidden" NAME="action" VALUE="login">
	<INPUT TYPE="hidden" NAME="nomenu" VALUE="[nomenu]">

        <TABLE BORDER=0 width=100% CELLSPACING=0 CELLPADDING=0>
         <TR BGCOLOR="[light_color]">
          <TD NOWRAP align=center>
     	      <INPUT TYPE=hidden NAME=list VALUE="[list]">
     	      <FONT SIZE=-1 COLOR="[selected_color]"><b>Email c�m:<INPUT TYPE=text NAME=email SIZE=20 VALUE="[init_email]">
      	      Jelsz�: </b>
              <INPUT TYPE=password NAME=passwd SIZE=8>&nbsp;&nbsp;
              <INPUT TYPE="submit" NAME="action_login" VALUE="Bel�p�s" SELECTED>
   	    </TD>
     	  </TR>
       </TABLE>
 </FORM> 

<CENTER>

    <B>email c�m</B>, a nyilv�ntartott email c�med<BR>
    <B>jelsz�</B>, a jelszavad.<BR><BR>

<TABLE border=0><TR>
<TD>
<I>Ha a szerverhezen nincsen jelszavad, vagy elfelejtetted, akkor:</I>
</TD><TD>
<TABLE CELLPADDING="2" CELLSPACING="2" WIDTH="100%" BORDER="0">
  <TR ALIGN=center BGCOLOR="[dark_color]">
  <TD>
  <TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="2">
     <TR> 
      <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center"> 
      [IF escaped_init_email]
         <A HREF="[path_cgi]/nomenu/sendpasswd/[escaped_init_email]"
      [ELSE]
         <A HREF="[path_cgi]/nomenu/remindpasswd/referer/[referer]"
      [ENDIF]
       onClick="window.open('','wws_login','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,copyhistory=no,width=450,height=300')" TARGET="wws_login">
     <FONT SIZE=-1><B>K�ldd el a jelszavamat</B></FONT></A>
     </TD>
    </TR>
  </TABLE>
</TR>
</TABLE>
</TD></TR></TABLE>
</CENTER>




