<!-- RCS Identication ; $Revision$ ; $Date$ -->


<FORM ACTION="[path_cgi]" METHOD=POST>

<P>
<TABLE>
 <TR>
   <TD NOWRAP><B>�ʵݱ�����:</B></TD>
   <TD><INPUT TYPE="text" NAME="listname" SIZE=30 VALUE="[saved->listname]"></TD>
   <TD><img src="/icons/unknown.png" alt="�ʵݱ�����ע�⣬�������ĵ�ַ!"></TD>
 </TR>
 
 <TR>
   <TD NOWRAP><B>������:</B></TD>
   <TD><I>[user->email]</I></TD>
   <TD><img src="/icons/unknown.png" alt="��������ʵݱ����Ȩ������"></TD>
 </TR>

 <TR>
   <TD valign=top NOWRAP><B>�ʵݱ�����: </B></TD>
   <TD>
     <MENU>
  [FOREACH template IN list_list_tpl]
     <INPUT TYPE="radio" NAME="template" Value="[template->NAME]"
     [IF template->selected]
       CHECKED
     [ENDIF]
     > [template->NAME]<BR>
     [PARSE template->comment]
     <BR>
  [END]
     </MENU>
    </TD>
    <TD valign=top><img src="/icons/unknown.png" alt="�ʵݱ������ǲ��������á��������ʵݱ�����༭����"></TD>
 </TR>
 <TR>
   <TD NOWRAP><B>����:</B></TD>
   <TD><INPUT TYPE="text" NAME="subject" SIZE=60 VALUE="[saved->subject]"></TD>
   <TD><img src="/icons/unknown.png" alt="�����ʵݱ������"></TD>
 </TR>
 <TR>
   <TD NOWRAP><B>����:</B></TD>
   <TD><SELECT NAME="topics">
	<OPTION VALUE="">--ѡ����--
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
   <TD valign=top><img src="/icons/unknown.png" alt="Ŀ¼�е��ʵݱ����"></TD>
 </TR>

 <TR>
   <TD valign=top NOWRAP><B>����:</B></TD>
   <TD><TEXTAREA COLS=60 ROWS=10 NAME="info">[saved->info]</TEXTAREA></TD>
   <TD valign=top><img src="/icons/unknown.png" alt="���ж��ʵݱ����������"></TD>
 </TR>

 <TR>
   <TD COLSPAN=2 ALIGN="center">
    <TABLE>
     <TR>
      <TD BGCOLOR="[light_color]">
<INPUT TYPE="submit" NAME="action_create_list" VALUE="�ύ���Ĵ�������">
      </TD>
     </TR></TABLE>
</TD></TR>
</TABLE>



</FORM>




