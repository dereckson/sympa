<FORM METHOD=POST ACTION="[path_cgi]">

<INPUT NAME=list TYPE=hidden VALUE="[list]">
<INPUT NAME=archive_name TYPE=hidden VALUE="[archive_name]">

<center>
<TABLE width=100%>
<TR><td bgcolor="#ccccff" align=center>
<font size=+1>������: </font><A HREF=[path_cgi]/arc/[list]/[archive_name]><font size=+2 color="#330099"><b>[archive_name]</b></font></A>
</TD><TD bgcolor="#ccccff" align=center>
<INPUT NAME=key_word     TYPE=text   SIZE=30 VALUE="[key_word]">
<INPUT NAME="action"  TYPE="hidden" Value="arcsearch">
<INPUT NAME=action_arcsearch TYPE=submit VALUE="����">
</TD></TR></TABLE>
 </center>
<P>

<TABLE CELLSPACING=0	CELLPADDING=0>

<TR VALIGN="TOP" NOWRAP>
<TD><b>����</b></TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="phrase" CHECKED> ��<font color="#330099"><B>һ��</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="all"> <font color="#330099"><b>ȫ��</b></font>��</TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="any"> <font color="#330099"><B>��һ</b></font>��</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>����</b></TD>
<TD><INPUT TYPE=RADIO NAME=age VALUE="new" CHECKED> <font color="#330099"><b>���µ�</b></font>�ʼ�</TD>
<TD><INPUT TYPE=RADIO NAME=age VALUE="old"> <font color="#330099"><b>��ɵ�</b></font>�ʼ�</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>��Сд</b></TD>
<TD><INPUT TYPE=RADIO NAME=case VALUE="off" CHECKED> <font color="#330099"><B>������</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=case VALUE="on"> <font color="#330099"><B>����</B></font></TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>���</b></TD>
<TD><INPUT TYPE=RADIO NAME=match VALUE="partial" CHECKED> <font color="#330099">���ʵ�<B>����</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=match VALUE="exact"> <font color="#330099"><B>����</b></font>����</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>����</b></TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="10" CHECKED> <font color="#330099">ÿҳ<B>10</b></font>�����</TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="25"> <font color="#330099">ÿҳ<B>25</b></font>�����</TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="50"> <font color="#330099">ÿҳ<B>50</b></font>�����</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>������</b></TD>
<TD><INPUT TYPE=checkbox NAME=from Value="True"> <font color="#330099"><B>������</B></font>

<TD><INPUT TYPE=checkbox NAME=subj Value="True"> <font color="#330099"> <B>����</B></font>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD>&#160;</TD>
<TD><INPUT TYPE=checkbox NAME=date Value="True"> <font color="#330099"><B>Date</B></font>

<TD><INPUT TYPE=checkbox NAME=body Value="True" checked> <font color="#330099"><B>Body</B></font>
</TR>

</TABLE>

<DL>
<DT><b>Extend search field</b>
<SELECT NAME="directories" MULTIPLE SIZE=4>    
<DD>

[FOREACH u IN yyyymm]

<OPTION VALUE="[u]">[u]

[END] 

</SELECT></DL>

</FORM>
