<!-- RCS Identication ; $Revision$ ; $Date$ -->

  <FORM ACTION="[path_cgi]" METHOD=POST>
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<TABLE>
<TR BGCOLOR="[bg_color]"><TD>
  <INPUT TYPE="submit" NAME="action_distribute" VALUE="Rozeslat">
  <INPUT TYPE="submit" NAME="action_reject.quiet" VALUE="Odm�tnout">
  <INPUT TYPE="submit" NAME="action_reject" VALUE="Odm�tnut� s upozorn�n�m">
</TD></TR></TABLE>  
    <TABLE BORDER="1" WIDTH="100%">
      <TR BGCOLOR="[dark_color]">
	<TH><FONT COLOR="[bg_color]">X</FONT></TH>
        <TH><FONT COLOR="[bg_color]">Datum</FONT></TH>
	<TH><FONT COLOR="[bg_color]">Autor</FONT></TH>
	<TH><FONT COLOR="[bg_color]">Subjekt</FONT></TH>
	<TH><FONT COLOR="[bg_color]">Velikost</FONT></TH>
      </TR>	 
      [FOREACH msg IN spool]
        <TR>
         <TD>
            <INPUT TYPE=checkbox name="id" value="[msg->NAME]">
	 </TD>
	  <TD>
	    [IF msg->date]
	      <FONT SIZE=-1>[msg->date]</FONT>
	    [ELSE]
	      &nbsp;
	    [ENDIF]
	  </TD>
	  <TD><FONT SIZE=-1>[msg->from]</FONT></TD>
	  <TD>
	    [IF msg->subject=no_subject]
	      <A HREF="[path_cgi]/viewmod/[list]/[msg->NAME]"><FONT SIZE=-1>Bez subjektu</FONT></A>
	    [ELSE]
	      <A HREF="[path_cgi]/viewmod/[list]/[msg->NAME]"><FONT SIZE=-1>[msg->subject]</FONT></A>
	    [ENDIF]
	  </TD>
	  <TD><FONT SIZE=-1>[msg->size] kB</FONT></TD>
	</TR>
      [END] 
    </TABLE>
<TABLE>
<TR BGCOLOR="[bg_color]"><TD>
  <INPUT TYPE="submit" NAME="action_distribute" VALUE="Rozeslat">
  <INPUT TYPE="submit" NAME="action_reject.quiet" VALUE="Odm�tnout">
  <INPUT TYPE="submit" NAME="action_reject" VALUE="Rozesl�n� s upozorn�n�m">
</TD></TR></TABLE>
</FORM>