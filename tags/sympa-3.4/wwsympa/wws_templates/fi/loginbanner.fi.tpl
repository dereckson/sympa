<!-- RCS Identication ; $Revision$ ; $Date$ -->

<BR>
[IF password_sent]
  Salasanasi on l�hetetty osoitteeseen [init_email].<BR>
  Tarkista postisi ja anna salasana alle.
  <BR><BR>
[ENDIF]

[IF action=loginrequest]
 Sinun t�ytyy kirjautua p��st�ksesi WWSympaan tai suorittamaan oikeutettuja
 toimontoja (vaatii email osoitteen).
[ELSE]
 Suurin osa ominaisuuksista vaatii email osoitteem. Jotkut osoitteet ovat piilossa
 tunnistamattomilta henkil�ilt�.<BR>
 Jos haluat k�ytt�� ominaisuuksia, sinun tulee tunnistautua ensin.<BR>
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
     	      <FONT SIZE=-1 COLOR="[selected_color]"><b>email <INPUT TYPE=text NAME=email SIZE=20 VALUE="[init_email]">
      	      salasana : </b>
              <INPUT TYPE=password NAME=passwd SIZE=8>&nbsp;&nbsp;
              <INPUT TYPE="submit" NAME="action_login" VALUE="Kirjaudu" SELECTED>
   	    </TD>
     	  </TR>
       </TABLE>
 </FORM> 

<CENTER>

    <B>email</B>, on tilaus osoite<BR>
    <B>salasana</B>, on salasana.<BR><BR>

<TABLE border=0><TR>
<TD>
<I>Jos et ole saanut salasanaa palvelimelta tai et muista sit� : </I>
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
     <FONT SIZE=-1><B>L�het� salasana</B></FONT></A>
     </TD>
    </TR>
  </TABLE>
</TR>
</TABLE>
</TD></TR></TABLE>
</CENTER>




