<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM ACTION="[path_cgi]" METHOD=POST>
<TABLE WIDTH="100%" BORDER=0>
<TR><TH BGCOLOR="#330099">
<FONT COLOR="#ffffff">�ʵݱ�������Ϣ</FONT>
</TH></TR><TR><TD>
<INPUT TYPE="hidden" NAME="previous_action" VALUE=[previous_action]>
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<INPUT TYPE="hidden" NAME="email" VALUE="[subscriber->escaped_email]">
<DL>
<DD>Email: <A HREF="mailto:[subscriber->email]">[subscriber->email]</A>
<DD>����: <INPUT NAME="gecos" VALUE="[subscriber->gecos]" SIZE="25">
<DD>����ʱ��: [subscriber->date]
<DD>����: <SELECT NAME="reception">
		  [FOREACH r IN reception]
		    <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
		  [END]
	        </SELECT>

<DD>�ɼ���: [subscriber->visibility]
<DD>����: [subscriber->lang]
<DD><INPUT TYPE="submit" NAME="action_set" VALUE="����">
<INPUT TYPE="submit" NAME="action_del" VALUE="ȡ���û��Ķ���">
<INPUT TYPE="checkbox" NAME="quiet"> ����
</DL>
</TD></TR>
[IF subscriber->bounce]
<TR><TH BGCOLOR="#ff6666">
<FONT COLOR="#ffffff">���ŵ�ַ</FONT>
</TD></TR><TR><TD>
<DL>
<DD>״̬: [subscriber->bounce_status] ([subscriber->bounce_code])
<DD>���ż���: [subscriber->bounce_count]
<DD>ʱ��: �� [subscriber->first_bounce] �� [subscriber->last_bounce]
<DD><A HREF="[path_cgi]/viewbounce/[list]/[subscriber->escaped_email]">�鿴��������</A>
<DD><INPUT TYPE="submit" NAME="action_resetbounce" VALUE="���ô������">
</DL>
</TD></TR>
[ENDIF]
</TABLE>
</FORM>



