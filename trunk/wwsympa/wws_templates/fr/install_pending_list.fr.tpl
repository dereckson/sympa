<!-- RCS Identication ; $Revision$ ; $Date$ -->

<br>

<BR>
<TABLE BORDER=0 WIDTH=100% >
<TR BGCOLOR="--LIGHT_COLOR--">
<TD>
<TABLE BORDER=0 WIDTH=100% >
<TR BGCOLOR="--LIGHT_COLOR--">
 <TD><B>Nom de liste :</B></TD><TD WIDTH=100% >[list]</TD>
</TR>
<TR BGCOLOR="--LIGHT_COLOR--">
 <TD><B>Objet : </B></TD><TD WIDTH=100%>[list_subject]</TD>
</TR>
<TR BGCOLOR="--LIGHT_COLOR--">
 <TD NOWRAP><B>Demand�e par </B></TD><TD WIDTH=100%>[list_request_by] <B>le</B> [list_request_date]</TD>
</TR>
</TABLE>
</TD>
</TR>
</TABLE>
<BR><BR>
[IF is_listmaster]
[IF auto_aliases]
Les alias ont �t� install�s.
[ELSE]
<TABLE BORDER=1>
<TR BGCOLOR="--LIGHT_COLOR--"><TD align=center>Les alias � installer </TD></TR>
<TR>
<TD>
<pre><code>
[aliases]
</code></pre>
</TD>
</TR>
</TABLE>
[ENDIF]
