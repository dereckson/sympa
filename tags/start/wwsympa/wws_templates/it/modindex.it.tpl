  <FORM ACTION="[path_cgi]" METHOD=POST>
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<TABLE>
<TR BGCOLOR="#ffffff"><TD>
  <INPUT TYPE="submit" NAME="action_distribute" VALUE="Distribuisci">
  <INPUT TYPE="submit" NAME="action_reject.quiet" VALUE="Rigetta">
  <INPUT TYPE="submit" NAME="action_reject" VALUE="Rigetta con notifica">
</TD></TR></TABLE>  
    <TABLE BORDER="1" WIDTH="100%">
      <TR BGCOLOR="#330099">
	<TH><FONT COLOR="#ffffff">X</FONT></TH>
        <TH><FONT COLOR="#ffffff">Data</FONT></TH>
	<TH><FONT COLOR="#ffffff">Autore</FONT></TH>
	<TH><FONT COLOR="#ffffff">Soggetto</FONT></TH>
	<TH><FONT COLOR="#ffffff">Grandezza</FONT></TH>
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
	      <A HREF="[path_cgi]/viewmod/[list]/[msg->NAME]"><FONT SIZE=-1>Nessun soggetto</FONT></A>
	    [ELSE]
	      <A HREF="[path_cgi]/viewmod/[list]/[msg->NAME]"><FONT SIZE=-1>[msg->subject]</FONT></A>
	    [ENDIF]
	  </TD>
	  <TD><FONT SIZE=-1>[msg->size] kb</FONT></TD>
	</TR>
      [END] 
    </TABLE>
<TABLE>
<TR BGCOLOR="#ffffff"><TD>
  <INPUT TYPE="submit" NAME="action_distribute" VALUE="Distribuisci">
  <INPUT TYPE="submit" NAME="action_reject.quiet" VALUE="Rigetta">
  <INPUT TYPE="submit" NAME="action_reject" VALUE="Rigetta e notifica">
</TD></TR></TABLE>
</FORM>











