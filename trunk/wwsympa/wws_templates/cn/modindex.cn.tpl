  <FORM ACTION="[path_cgi]" METHOD=POST>
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<TABLE>
<TR BGCOLOR="--BG_COLOR--"><TD>
  <INPUT TYPE="submit" NAME="action_distribute" VALUE="�ַ�">
  <INPUT TYPE="submit" NAME="action_reject.quiet" VALUE="�ܾ�">
  <INPUT TYPE="submit" NAME="action_reject" VALUE="�ܾ���֪ͨ">
</TD></TR></TABLE>  
    <TABLE BORDER="1" WIDTH="100%">
      <TR BGCOLOR="--DARK_COLOR--">
	<TH><FONT COLOR="--BG_COLOR--">X</FONT></TH>
        <TH><FONT COLOR="--BG_COLOR--">����</FONT></TH>
	<TH><FONT COLOR="--BG_COLOR--">����</FONT></TH>
	<TH><FONT COLOR="--BG_COLOR--">����</FONT></TH>
	<TH><FONT COLOR="--BG_COLOR--">��С</FONT></TH>
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
	      <A HREF="[path_cgi]/viewmod/[list]/[msg->NAME]"><FONT SIZE=-1>û�б���</FONT></A>
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
  <INPUT TYPE="submit" NAME="action_distribute" VALUE="�ַ�">
  <INPUT TYPE="submit" NAME="action_reject.quiet" VALUE="�ܾ�">
  <INPUT TYPE="submit" NAME="action_reject" VALUE="�ܾ���֪ͨ">
</TD></TR></TABLE>
</FORM>












