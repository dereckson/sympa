<!-- RCS Identication ; $Revision$ ; $Date$ -->

<BR>
[IF password_sent]
  Va�e heslo bylo odesl�no na Va�i emailovou adresu [init_email].<BR>
  Pros�m prohl�dn�te si Va�i emailovou schr�nku a napi�te dol� Va�e heslo.
  <BR><BR>
[ENDIF]

[IF action=loginrequest]
 Pro p��stup k Va�emu prost�ed� na WWSympa nebo k prov�d�n� privilegovan�ch 
operaci (ty, kter� vy�aduj� emailovou adresu) se mus�te p�ihl�sit.
[ELSE]
V�t�ina mo�nost� konference vy�aduje Va�i emailovou adresu. N�kter� konference
jsou skryt� nezn�m�m osob�m.<BR>
Abyste mohli vyu��t v�echny slu�by, kter� nab�z� tento server, mus�te se
nejprve identifikovat. <BR>
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
     	      <FONT SIZE=-1 COLOR="[selected_color]"><b>emailov� adresa <INPUT TYPE=text NAME=email SIZE=20 VALUE="[init_email]">
      	      heslo : </b>
              <INPUT TYPE=password NAME=passwd SIZE=8>&nbsp;&nbsp;
              <INPUT TYPE="submit" NAME="action_login" VALUE="P�ihl�sit se" SELECTED>
   	    </TD>
     	  </TR>
       </TABLE>
 </FORM> 

<CENTER>

    <B>emailov� adresa</B>, je Va�e �lensk� emailov� adresa<BR>
    <B>heslo</B>, je Va�e heslo.<BR><BR>

<TABLE border=0><TR>
<TD>
<I>Pokud na tomto serveru nem�te heslo nebo si ho nepamatujete :</I>
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
     <FONT SIZE=-1><B>Za�lete mi heslo</B></FONT></A>
     </TD>
    </TR>
  </TABLE>
</TR>
</TABLE>
</TD></TR></TABLE>
</CENTER>
