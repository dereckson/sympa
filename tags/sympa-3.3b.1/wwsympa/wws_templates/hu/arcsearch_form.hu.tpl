<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM METHOD=POST ACTION="[path_cgi]">

<INPUT NAME=list TYPE=hidden VALUE="[list]">
<INPUT NAME=archive_name TYPE=hidden VALUE="[archive_name]">

<center>
<TABLE width=100%>
<TR><td bgcolor="[light_color]" align=center>
<font size=+1>Keres�si tartom�ny: </font><A HREF=[path_cgi]/arc/[list]/[archive_name]><font size=+2 color="[dark_color]"><b>[archive_name]</b></font></A>
</TD><TD bgcolor="[light_color]" align=center>
<INPUT NAME=key_word     TYPE=text   SIZE=30 VALUE="[key_word]">
<INPUT NAME="action"  TYPE="hidden" Value="arcsearch">
<INPUT NAME=action_arcsearch TYPE=submit VALUE="Keres�s">
</TD></TR></TABLE>
 </center>
<P>

<TABLE CELLSPACING=0	CELLPADDING=0>

<TR VALIGN="TOP" NOWRAP>
<TD><b>Keres�s</b></TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="phrase" CHECKED> eg�sz <font color="[dark_color]"><B>mondatot</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="all"> <font color="[dark_color]"><b>minden</b></font> sz�t</TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="any"> <font color="[dark_color]"><B>b�rmelyik</b></font> sz�t</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Tal�latok megjelen�t�se</b></TD>
<TD><INPUT TYPE=RADIO NAME=age VALUE="new" CHECKED> <font color="[dark_color]"><b>�jabbak</b></font> el�l</TD>
<TD><INPUT TYPE=RADIO NAME=age VALUE="old"> <font color="[dark_color]"><b>r�gebbiek</b></font> el�l</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Kis- �s nagybet�k </b></TD>
<TD><INPUT TYPE=RADIO NAME=case VALUE="off" CHECKED> <font color="[dark_color]"><B>nem sz�m�tanak</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=case VALUE="on"> <font color="[dark_color]"><B>sz�m�tanak</B></font></TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Egyez�s</b></TD>
<TD><INPUT TYPE=RADIO NAME=match VALUE="partial" CHECKED>a sz� <font color="[dark_color]"><B>r�sze</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=match VALUE="exact"> <font color="[dark_color]"><B>teljesen egyezik</b></font> a sz�val</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Tal�latok felsorol�sa</b></TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="10" CHECKED> <font color="[dark_color]"><B>10</b></font> tal�lat oldalank�nt
</TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="25"> <font color="[dark_color]"><B>25</b></font> tal�lat oldalank�nt</TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="50"> <font color="[dark_color]"><B>50</b></font> tal�lat oldalank�nt</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>A lev�l melyik r�sz�ben keressen?</b></TD>
<TD><INPUT TYPE=checkbox NAME=from Value="True"> <font color="[dark_color]"><B>Felad�</B></font>

<TD><INPUT TYPE=checkbox NAME=subj Value="True"> <font color="[dark_color]"> <B>T�rgy</B></font>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD>&#160;</TD>
<TD><INPUT TYPE=checkbox NAME=date Value="True"> <font color="[dark_color]"><B>D�tum</B></font>

<TD><INPUT TYPE=checkbox NAME=body Value="True" checked> <font color="[dark_color]"><B>T�rzs</B></font>
</TR>

</TABLE>

<DL>
<DT><b>B�v�tett keres�si tartom�ny</b>
<SELECT NAME="directories" MULTIPLE SIZE=4>    
<DD>

[FOREACH u IN yyyymm]

<OPTION VALUE="[u]">[u]

[END] 

</SELECT></DL>

</FORM>
