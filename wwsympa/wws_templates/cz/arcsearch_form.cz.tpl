<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM METHOD=POST ACTION="[path_cgi]">

<INPUT NAME=list TYPE=hidden VALUE="[list]">
<INPUT NAME=archive_name TYPE=hidden VALUE="[archive_name]">

<center>
<TABLE width=100%>
<TR><td bgcolor="#ccccff" align=center>
<font size=+1>Vyhled�vac� pole : </font><A HREF=[path_cgi]/arc/[list]/[archive_name]><font size=+2 color="#330099"><b>[archive_name]</b></font></A>
</TD><TD bgcolor="#ccccff" align=center>
<INPUT NAME=key_word     TYPE=text   SIZE=30 VALUE="[key_word]">
<INPUT NAME="action"  TYPE="hidden" Value="arcsearch">
<INPUT NAME=action_arcsearch TYPE=submit VALUE="Hledej">
</TD></TR></TABLE>
 </center>
<P>

<TABLE CELLSPACING=0	CELLPADDING=0>

<TR VALIGN="TOP" NOWRAP>
<TD><b>Hled�n�</b></TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="phrase" CHECKED> tato <font color="#330099"><B>v�ta</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="all"> <font color="#330099"><b>v�echny</b></font> slova</TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="any"> <font color="#330099"><B>jak�koliv</b></font> slovo</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>D�vat p�ednost</b></TD>
<TD><INPUT TYPE=RADIO NAME=age VALUE="new" CHECKED> <font color="#330099"><b>nejnov�j��m</b></font> zpr�vam</TD>
<TD><INPUT TYPE=RADIO NAME=age VALUE="old"> <font color="#330099"><b>nejstar��m</b></font> zpr�v�m</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Velkost p�smen</b></TD>
<TD><INPUT TYPE=RADIO NAME=case VALUE="off" CHECKED> <font color="#330099"><B>nerozli�ovat</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=case VALUE="on"> <font color="#330099"><B>rozli�ovat</B></font></TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Shoda</b></TD>
<TD><INPUT TYPE=RADIO NAME=match VALUE="partial" CHECKED> <font color="#330099"><B>��st</b></font> slova</TD>
<TD><INPUT TYPE=RADIO NAME=match VALUE="exact"> <font color="#330099"><B>cel�</b></font> slovo</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Uspo��d�n�</b></TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="10" CHECKED> <font color="#330099"><B>10</b></font> v�sledk� na stranu
</TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="25"> <font color="#330099"><B>25</b></font> v�sledk� na stranu</TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="50"> <font color="#330099"><B>50</b></font> v�sledk� na stranu</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Kde hledat</b></TD>
<TD><INPUT TYPE=checkbox NAME=from Value="True"> <font color="#330099"><B>Odes�latel</B></font>

<TD><INPUT TYPE=checkbox NAME=subj Value="True"> <font color="#330099"> <B>Subjekt</B></font>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD>&#160;</TD>
<TD><INPUT TYPE=checkbox NAME=date Value="True"> <font color="#330099"><B>Datum</B></font>

<TD><INPUT TYPE=checkbox NAME=body Value="True" checked> <font color="#330099"><B>T�lo zpr�vy</B></font>
</TR>

</TABLE>

<DL>
<DT><b>Roz���it pole hled�n�</b>
<SELECT NAME="directories" MULTIPLE SIZE=4>    
<DD>

[FOREACH u IN yyyymm]

<OPTION VALUE="[u]">[u]

[END] 

</SELECT></DL>

</FORM>
