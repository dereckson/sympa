<FORM ACTION="[path_cgi]" METHOD="POST"> 
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">

    <TABLE WIDTH="100%" BORDER="1">
      <TR BGCOLOR="[dark_color]">
        <TH><FONT SIZE="-1" COLOR="[bg_color]"><B>X</B></FONT></TH>
        <TH NOWRAP COLSPAN=2 >
	<FONT COLOR="[bg_color]" SIZE="-1"><b>E-post</b></FONT></TH>
        <TH><FONT COLOR="[bg_color]" SIZE="-1"><B>Nimi</B></FONT></TH>
        <TH NOWRAP>
	<FONT COLOR="[bg_color]" SIZE="-1"><b>Kuup�ev</b></FONT></TH>
      </TR>
      
      [IF subscriptions]

      [FOREACH sub IN subscriptions]

	[IF dark=1]
	  <TR BGCOLOR="[shaded_color]">
	[ELSE]
          <TR>
	[ENDIF]
	    <TD>
           <INPUT TYPE=checkbox name="email" value="[sub->NAME],[sub->gecos]">
	    </TD>
	  <TD COLSPAN=2 NOWRAP><FONT SIZE=-1>
	        [sub->NAME]
	  </FONT></TD>
	  <TD>
             <FONT SIZE=-1>
	        [sub->gecos]&nbsp;
	     </FONT>
          </TD>
	    <TD ALIGN="center"NOWRAP><FONT SIZE=-1>
	      [sub->date]
	    </FONT></TD>
        </TR>

        [IF dark=1]
	  [SET dark=0]
	[ELSE]
	  [SET dark=1]
	[ENDIF]

        [END]

        [ELSE]
         <TR COLSPAN="4"><TH>Listiga liitumise soove ei ole</TH></TR>
        [ENDIF]
      </TABLE>

<INPUT TYPE="submit" NAME="action_add" VALUE="Lisa valitud aadressid">
<INPUT TYPE="submit" NAME="action_ignoresub" VALUE="Eemalda valitud aadressid">
</FORM>
