<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM METHOD=POST ACTION="[path_cgi]">

<INPUT NAME=list TYPE=hidden VALUE="[list]">
<INPUT NAME=archive_name TYPE=hidden VALUE="[archive_name]">

<center>
<TABLE width=100%>
<TR><td bgcolor="--LIGHT_COLOR--" align=center>
<font size=+1>Keresend� kifejez�s: </font><A HREF=[path_cgi]/arc/[list]/[archive_name]><font size=+2 color="--DARK_COLOR--"><b>[archive_name]</b></font></A>
</TD><TD bgcolor="--LIGHT_COLOR--" align=center>
<INPUT NAME=key_word     TYPE=text   SIZE=30 VALUE="[key_word]">
<INPUT NAME="action"  TYPE="hidden" Value="arcsearch">
<INPUT NAME=action_arcsearch TYPE=submit VALUE="Keres�s">
</TD></TR></TABLE>
 </center>
<P>

<TABLE CELLSPACING=0	CELLPADDING=0>

<TR VALIGN="TOP" NOWRAP>
<TD><b>Keres�s</b></TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="phrase" CHECKED> ezt a <font color="--DARK_COLOR--"><B>kifejez�st</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="all"> <font color="--DARK_COLOR--"><b>az �sszes</b></font> sz�t</TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="any"> <font color="--DARK_COLOR--"><B>b�rmlyik</b></font> sz�t</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Kijelz�s</b></TD>
<TD><INPUT TYPE=RADIO NAME=age VALUE="new" CHECKED> <font color="--DARK_COLOR--"><b>�jabbak</b></font> el�l</TD>
<TD><INPUT TYPE=RADIO NAME=age VALUE="old"> <font color="--DARK_COLOR--"><b>r�gebbiek</b></font> el�l</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Bet�k </b></TD>
<TD><INPUT TYPE=RADIO NAME=case VALUE="off" CHECKED> <font color="--DARK_COLOR--"><B>kis-, nagybet� nem sz�m�t</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=case VALUE="on"> <font color="--DARK_COLOR--"><B>kis, nagybet� sz�m�t</B></font></TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Egyez�s</b></TD>
<TD><INPUT TYPE=RADIO NAME=match VALUE="partial" CHECKED> <font color="--DARK_COLOR--"><B>a sz� r�sze</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=match VALUE="exact"> <font color="--DARK_COLOR--"><B>teljesen egyezik</b></font> a sz�val</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Kimenet</b></TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="10" CHECKED> <font color="--DARK_COLOR--"><B>10</b></font> tal�lat oldalank�nt
</TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="25"> <font color="--DARK_COLOR--"><B>25</b></font> tal�lat oldalank�nt</TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="50"> <font color="--DARK_COLOR--"><B>50</b></font> tal�lat oldalank�nt</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>A lev�l melyik r�sz�ben keressen?</b></TD>
<TD><INPUT TYPE=checkbox NAME=from Value="True"> <font color="--DARK_COLOR--"><B>Felad�</B></font>

<TD><INPUT TYPE=checkbox NAME=subj Value="True"> <font color="--DARK_COLOR--"> <B>T�rgy</B></font>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD>&#160;</TD>
<TD><INPUT TYPE=checkbox NAME=date Value="True"> <font color="--DARK_COLOR--"><B>D�tum</B></font>

<TD><INPUT TYPE=checkbox NAME=body Value="True" checked> <font color="--DARK_COLOR--"><B>T�rzs</B></font>
</TR>

</TABLE>

<DL>
<DT><b>B�v�tett keres�s</b>
<SELECT NAME="directories" MULTIPLE SIZE=4>    
<DD>

[FOREACH u IN yyyymm]

<OPTION VALUE="[u]">[u]

[END] 

</SELECT></DL>

</FORM>
