<!-- RCS Identication ; $Revision$ ; $Date$ -->


<FORM ACTION="[path_cgi]" METHOD=POST>

<HR  WIDTH=90%>

<P>
<TABLE>
 <TR>
   <TD Colspan=3 bgcolor="#ccccff"><B>�ekaj�c� konference</B></TD>
 </TR>
 <TR bgcolor="#ccccff">
   <TD><B>jm�no</B></TD>
   <TD><B>subjekt</B></TD>
   <TD><B>kdo po�aduje</B></TD>
 </TR>

[FOREACH list IN pending]
<TR>
<TD><A HREF="[path_cgi]/set_pending_list_request/[list->NAME]">[list->NAME]</A></TD></TD>
<TD>[list->subject]</TD>
<TD>[list->by]</TD>
</TR>
[END]
</TABLE>
