<!-- RCS Identication ; $Revision$ ; $Date$ -->

<H1>�ĵ� [path] �ķ���Ȩ��</H1>
    ������: [owner] <BR>
    ������: [doc_date] <BR>
    ����: [doc_title] <BR><BR>
<H3><A HREF="[path_cgi]/d_read/[list]/[father]"> <IMG ALIGN="bottom"  src="[father_icon]"> ת����һ��Ŀ¼</A></H3>

<TABLE width=100%>

  <TR VALIGN="top">
  <TD>

  <FORM ACTION="[path_cgi]" METHOD="POST">
  <B>��ȡ</B><BR>
  <SELECT NAME="read_access">
  [FOREACH s IN scenari_read]
    <OPTION VALUE='[s->scenario_name]' [s->selected]>[s->scenario_label]
  [END]
  </SELECT>
  <BR>

  <B>�༭</B><BR>
  <SELECT NAME="edit_access">
  [FOREACH s IN scenari_edit]
    <OPTION VALUE='[s->scenario_name]' [s->selected]>[s->scenario_label]
  [END]
  </SELECT>
  <BR>
   
   <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
   <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
   <INPUT TYPE="hidden" NAME="serial" VALUE="[serial_desc]">
   <INPUT TYPE="submit" NAME="action_d_change_access" VALUE="�޸�Ȩ��">
   </FORM>

   </TD>

   [IF set_owner]
     <TD>
     <B>����Ŀ¼ [path] ��������</B>

     <FORM ACTION="[path_cgi]" METHOD="POST">
     <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
     <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
     <INPUT TYPE="hidden" NAME="serial" VALUE="[serial_desc]">
     <INPUT TYPE="hidden" NAME="action" VALUE="d_set_owner">
     <INPUT MAXLENGTH=50 NAME="content" VALUE="[owner]" SIZE=30>
     <INPUT TYPE="submit" NAME="action_d_set_owner" VALUE="����������">
     </FORM>

     </TD>
  [ENDIF]

</TR>

</TABLE>

