<!-- RCS Identication ; $Revision$ ; $Date$ -->

  <FORM ACTION="[path_cgi]" METHOD=POST>
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<TABLE>
<TR BGCOLOR="--BG_COLOR--"><TD>
  <INPUT TYPE="submit" NAME="action_distribute" VALUE="Enged�lyez">
  <INPUT TYPE="submit" NAME="action_reject.quiet" VALUE="Elutas�t">
  <INPUT TYPE="submit" NAME="action_reject" VALUE="Elutas�t �s �rtes�t">
</TD></TR></TABLE>  
    <TABLE BORDER="1" WIDTH="100%">
      <TR BGCOLOR="--DARK_COLOR--">
	<TH><FONT COLOR="--BG_COLOR--">X</FONT></TH>
        <TH><FONT COLOR="--BG_COLOR--">D�tum</FONT></TH>
	<TH><FONT COLOR="--BG_COLOR--">Szerz�</FONT></TH>
	<TH><FONT COLOR="--BG_COLOR--">T�rgy</FONT></TH>
	<TH><FONT COLOR="--BG_COLOR--">M�ret</FONT></TH>
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
	      <A HREF="[path_cgi]/viewmod/[list]/[msg->NAME]"><FONT SIZE=-1>Nincs t�rgy megadva</FONT></A>
	    [ELSE]
	      <A HREF="[path_cgi]/viewmod/[list]/[msg->NAME]"><FONT SIZE=-1>[msg->subject]</FONT></A>
	    [ENDIF]
	  </TD>
	  <TD><FONT SIZE=-1>[msg->size] kb</FONT></TD>
	</TR>
      [END] 
    </TABLE>
<TABLE>
<TR BGCOLOR="--BG_COLOR--"><TD>
  <INPUT TYPE="submit" NAME="action_distribute" VALUE="Enged�lyez">
  <INPUT TYPE="submit" NAME="action_reject.quiet" VALUE="Elutas�t">
  <INPUT TYPE="submit" NAME="action_reject" VALUE="Elutas�t �s �rtes�t">
</TD></TR></TABLE>
</FORM>












