<!-- RCS Identication ; $Revision$ ; $Date$ -->


<FORM ACTION="[path_cgi]" METHOD=POST>

<P>
<TABLE>
 <TR>
      <TD NOWRAP><B>Denumire lista:</B></TD>
   <TD><INPUT TYPE="text" NAME="listname" SIZE=30 VALUE="[saved->listname]"></TD>
   <TD><img src="[icons_url]/unknown.png" alt="the list name ; be careful, not its address !"></TD>
 </TR>
 
 <TR>
      <TD NOWRAP><B>Proprietar:</B></TD>
   <TD><I>[user->email]</I></TD>
   <TD><img src="[icons_url]/unknown.png" alt="You are the privileged owner of this list"></TD>
 </TR>

 <TR>
      <TD valign=top NOWRAP><B>Tip lista:</B></TD>
   <TD>
     <MENU>
  [FOREACH template IN list_list_tpl]
     <INPUT TYPE="radio" NAME="template" Value="[template->NAME]"
     [IF template->selected]
       CHECKED
     [ENDIF]
     > [template->NAME]<BR>
     <BLOCKQUOTE>
     [PARSE template->comment]
     </BLOCKQUOTE>
     <BR>
  [END]
     </MENU>
    </TD>
    <TD valign=top><img src="[icons_url]/unknown.png" alt="The list type is a set of parameters' profile. Parameters will be editable, once the list created"></TD>
 </TR>
 <TR>
      <TD NOWRAP><B>Subiect:</B></TD>
   <TD><INPUT TYPE="text" NAME="subject" SIZE=60 VALUE="[saved->subject]"></TD>
   <TD><img src="[icons_url]/unknown.png" alt="The list's subject"></TD>
 </TR>
 <TR>
      <TD NOWRAP><B>Teme:</B></TD>
   <TD><SELECT NAME="topics">
	<OPTION VALUE="">--Select a topic--
	[FOREACH topic IN list_of_topics]
	  <OPTION VALUE="[topic->NAME]"
	  [IF topic->selected]
	    SELECTED
	  [ENDIF]
	  >[topic->title]
	  [IF topic->sub]
	  [FOREACH subtopic IN topic->sub]
	     <OPTION VALUE="[topic->NAME]/[subtopic->NAME]">[topic->title] / [subtopic->title]
	  [END]
	  [ENDIF]
	[END]
	<OPTION VALUE="other">Other
     </SELECT>
   </TD>
   <TD valign=top><img src="[icons_url]/unknown.png" alt="List classification in the directory"></TD>
 </TR>

 <TR>
      <TD valign=top NOWRAP><B>Descriere:</B></TD>
   <TD><TEXTAREA COLS=60 ROWS=10 NAME="info">[saved->info]</TEXTAREA></TD>
   <TD valign=top><img src="[icons_url]/unknown.png" alt="A few lines describing the list"></TD>
 </TR>

 <TR>
   <TD COLSPAN=2 ALIGN="center">
    <TABLE>
     <TR>
      <TD BGCOLOR="[light_color]">
              <INPUT TYPE="submit" NAME="action_create_list" VALUE="Trimite cererea pentru crearea listei">
      </TD>
     </TR></TABLE>
</TD></TR>
</TABLE>



</FORM>



