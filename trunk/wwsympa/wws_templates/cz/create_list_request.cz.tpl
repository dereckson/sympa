<!-- RCS Identication ; $Revision$ ; $Date$ -->


<FORM ACTION="[path_cgi]" METHOD=POST>

<P>
<TABLE>
 <TR>
   <TD NOWRAP><B>Jm�no konference:</B></TD>
   <TD><INPUT TYPE="text" NAME="listname" SIZE=30 VALUE="[saved->listname]"></TD>
   <TD><img src="/icons/unknown.png" alt="jm�no konference ; ne jej� adresu!"></TD>
 </TR>
 
 <TR>
   <TD NOWRAP><B>Vlastn�k:</B></TD>
   <TD><I>[user->email]</I></TD>
   <TD><img src="/icons/unknown.png" alt="Jste vlastn�kem konference"></TD>
 </TR>

 <TR>
   <TD valign=top NOWRAP><B>Typ konference :</B></TD>
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
    <TD valign=top><img src="/icons/unknown.png" alt="Typ konference je p�ednastaven� profil. Parametry se budou moci m�nit, a� se konference vytvo��"></TD>
 </TR>
 <TR>
   <TD NOWRAP><B>P�edm�t:</B></TD>
   <TD><INPUT TYPE="text" NAME="subject" SIZE=60 VALUE="[saved->subject]"></TD>
   <TD><img src="/icons/unknown.png" alt="T�ma konference"></TD>
 </TR>
 <TR>
   <TD NOWRAP><B>T�mata:</B></TD>
   <TD><SELECT NAME="topics">
	<OPTION VALUE="">--Vyberte t�mata--
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
   <TD valign=top><img src="/icons/unknown.png" alt="Klasifikace konference v adres��i"></TD>
 </TR>

 <TR>
   <TD valign=top NOWRAP><B>Popis:</B></TD>
   <TD><TEXTAREA COLS=60 ROWS=10 NAME="info">[saved->info]</TEXTAREA></TD>
   <TD valign=top><img src="/icons/unknown.png" alt="N�kolik ��dk� popisuj�c�ch konferenci"></TD>
 </TR>

 <TR>
   <TD COLSPAN=2 ALIGN="center">
    <TABLE>
     <TR>
      <TD BGCOLOR="[light_color]">
<INPUT TYPE="submit" NAME="action_create_list" VALUE="Odeslat po�adavek na vytvo�en�">
      </TD>
     </TR></TABLE>
</TD></TR>
</TABLE>



</FORM>
