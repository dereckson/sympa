<!-- RCS Identication ; $Revision$ ; $Date$ -->

<H2>�ڴ浵�������Ľ��
<A HREF="[path_cgi]/arc/[list]/[archive_name]"><FONT COLOR="[dark_color]">[list]</font></a>: </H2>

<P>������:
[FOREACH u IN directories]
<A HREF="[path_cgi]/arc/[list]/[u]"><FONT COLOR="[dark_color]">[u]</font></a> - 
[END]
</P>

���Ҳ�����Ӧ�÷�Χ <b> &quot;[key_word]&quot;</b>
<I>

[IF how=phrase]
	(���仰��
[ELSIF how=any]
	(���еĴʣ�
[ELSE]
	(ÿ���ʣ�
[ENDIF]

<i>

[IF case]
	�����ִ�Сд
[ELSE]
	���ִ�Сд
[ENDIF]

[IF match]
	�ͼ��ʵĲ���)</i>
[ELSE]
	�ͼ��������)</i>
[ENDIF]
<p>

<HR>

[IF age]
	<B>�����ʼ�����</b><P>
[ELSE]
	<B>����ʼ�����</b><P>
[ENDIF]

[FOREACH u IN res]
	<DT><A HREF=[u->file]>[u->subj]</A> -- <EM>[u->date]</EM><DD>[u->from]<PRE>[u->body_string]</PRE>
[END]

<DL>
<B>���</b>
<DT><B>�� [num] ��ѡ���� [searched] ���ʼ� ...</b><BR>

[IF body]
	<DD>�����ʼ�<i>����</i>�� <B>[body_count]</b> ������<BR>
[ENDIF]

[IF subj]
	<DD>�����ʼ�<i>����</i>�� <B>[subj_count]</b> ������<BR>
[ENDIF]

[IF from]
	<DD>�����ʼ�<i>������</i>�� <B>[from_count]</b> ������<BR>
[ENDIF]

[IF date]
	<DD>�����ʼ�<i>����</i>�� <B>[date_count]</b> ������<BR>
[ENDIF]

</dl>

<FORM METHOD=POST ACTION="[path_cgi]">
<INPUT TYPE=hidden NAME=list		 VALUE="[list]">
<INPUT TYPE=hidden NAME=archive_name VALUE="[archive_name]">
<INPUT TYPE=hidden NAME=key_word     VALUE="[key_word]">
<INPUT TYPE=hidden NAME=how          VALUE="[how]">
<INPUT TYPE=hidden NAME=age          VALUE="[age]">
<INPUT TYPE=hidden NAME=case         VALUE="[case]">
<INPUT TYPE=hidden NAME=match        VALUE="[match]">
<INPUT TYPE=hidden NAME=limit        VALUE="[limit]">
<INPUT TYPE=hidden NAME=body_count   VALUE="[body_count]">
<INPUT TYPE=hidden NAME=date_count   VALUE="[date_count]">
<INPUT TYPE=hidden NAME=from_count   VALUE="[from_count]">
<INPUT TYPE=hidden NAME=subj_count   VALUE="[subj_count]">
<INPUT TYPE=hidden NAME=previous     VALUE="[searched]">

[IF body]
	<INPUT TYPE=hidden NAME=body Value="[body]">
[ENDIF]

[IF subj]
	<INPUT TYPE=hidden NAME=subj Value="[subj]">
[ENDIF]

[IF from]
	<INPUT TYPE=hidden NAME=from Value="[from]">
[ENDIF]

[IF date]
	<INPUT TYPE=hidden NAME=date Value="[date]">
[ENDIF]

[FOREACH u IN directories]
	<INPUT TYPE=hidden NAME=directories Value="[u]">
[END]

[IF continue]
	<INPUT NAME=action_arcsearch TYPE=submit VALUE="��������">
[ENDIF]

<INPUT NAME=action_arcsearch_form TYPE=submit VALUE="�µĲ���">
</FORM>
<HR>
����<Font size=+1 color="[dark_color]"><i><A HREF="http://www.mhonarc.org/contrib/marc-search/">Marc-Search</a></i></font>��<B>MHonArc</B>�鵵����������<p>


<A HREF="[path_cgi]/arc/[list]/[archive_name]"><B>�ص��鵵 [archive_name] 
</B></A><br>
