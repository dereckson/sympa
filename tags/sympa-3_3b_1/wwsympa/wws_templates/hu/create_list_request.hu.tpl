<!-- RCS Identication ; $Revision$ ; $Date$ -->


<FORM ACTION="[path_cgi]" METHOD=POST>

<P>
<TABLE>
 <TR>
   <TD NOWRAP><B>Lista neve:</B></TD>
   <TD><INPUT TYPE="text" NAME="listname" SIZE=30 VALUE="[saved->listname]"></TD>
   <TD><img src="/icons/unknown.gif" alt="A lista neve; nem a c�me!"></TD>
 </TR>
 
 <TR>
   <TD NOWRAP><B>Tulajdonos:</B></TD>
   <TD><I>[user->email]</I></TD>
   <TD><img src="/icons/unknown.gif" alt="A lista kiemelt gazd�ja leszel!"></TD>
 </TR>

 <TR>
   <TD valign=top NOWRAP><B>A lista t�pusa:</B></TD>
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
    <TD valign=top><img src="/icons/unknown.gif" alt="A lista t�pus�t annak be�ll�t�sa adja meg. A be�ll�t�sokat a lista l�trehoz�sa ut�n lehet elv�gezni."></TD>
 </TR>
 <TR>
   <TD NOWRAP><B>T�rgy:</B></TD>
   <TD><INPUT TYPE="text" NAME="subject" SIZE=60 VALUE="[saved->subject]"></TD>
   <TD><img src="/icons/unknown.gif" alt="Amir�l a lista sz�l"></TD>
 </TR>
 <TR>
   <TD NOWRAP><B>T�mak�r�k:</B></TD>
   <TD><SELECT NAME="topics">
	<OPTION VALUE="">--V�lassz egyet--
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
     </SELECT>
   </TD>
   <TD valign=top><img src="/icons/unknown.gif" alt="A lista besorol�sa"></TD>
 </TR>

 <TR>
   <TD valign=top NOWRAP><B>Le�r�s:</B></TD>
   <TD><TEXTAREA COLS=60 ROWS=10 NAME="info">[saved->info]</TEXTAREA></TD>
   <TD valign=top><img src="/icons/unknown.gif" alt="A list�r�l p�r sz�"></TD>
 </TR>

 <TR>
   <TD COLSPAN=2 ALIGN="center">
    <TABLE>
     <TR>
      <TD BGCOLOR="[light_color]">
<INPUT TYPE="submit" NAME="action_create_list" VALUE="K�relem elk�ld�se">
      </TD>
     </TR></TABLE>
</TD></TR>
</TABLE>



</FORM>




