<!-- RCS Identication ; $Revision$ ; $Date$ -->


<TABLE WIDTH="100%">
 <TR bgcolor="[light_color]">
    <TD><B>Data crearii</B></TD>
    <TD><B>Denumire lista</B></TD>
    <TD><B>Subiect</B></TD>
 </TR>

[FOREACH list IN latest_lists]
<TR>
<TD>[list->creation_date]</TD>
<TD><A HREF="[path_cgi]/admin/[list->name]">[list->name]</A></TD>
<TD>[list->subject]</TD>
</TR>
[END]
</TABLE>




