<!-- RCS Identication ; $Revision$ ; $Date$ -->

<br>

<BR>
<TABLE BORDER=0 WIDTH=100% >
<TR BGCOLOR="--LIGHT_COLOR--">
<TD>
<TABLE BORDER=0 WIDTH=100% >
<TR BGCOLOR="--LIGHT_COLOR--">
 <TD><B>Nombre de la Lista:</B></TD><TD WIDTH=100% >[list]</TD>
</TR>
<TR BGCOLOR="--LIGHT_COLOR--">
 <TD><B>Tema : </B></TD><TD WIDTH=100%>[list_subject]</TD>
</TR>
<TR BGCOLOR="--LIGHT_COLOR--">
 <TD NOWRAP><B>Lista solicitada por </B></TD><TD WIDTH=100%>[list_request_by] <B>el</B> [list_request_date]</TD>
</TR>
</TABLE>
</TD>
</TR>
</TABLE>
<BR><BR>
[IF is_listmaster]
[IF list_status=pending]
<TABLE BORDER=0>
<TR>
<TD>
<FORM ACTION="[path_cgi]" METHOD=POST>
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<INPUT TYPE="hidden" NAME="serial" VALUE="[list_serial]">

<MENU>
<INPUT TYPE="radio" NAME="status" VALUE="closed">Cerrarla &nbsp;&nbsp;
<INPUT TYPE="radio" NAME="status" VALUE="open">Instalarla &nbsp;&nbsp;
</MENU>
</TD><TD>
<TD BGCOLOR="--LIGHT_COLOR--">
<INPUT TYPE="submit" NAME="action_install_pending_list" VALUE="Aceptar">
</FORM>
</TD>
</TR>
</TABLE>
<BR><HR><BR>
[ENDIF]
[ENDIF]
<TABLE BORDER=0 WIDTH=100%>
<TR>
 <TD ALIGN=CENTER>
   <B>Informaci�n del fichero</B> 
   [IF is_listmaster]
      ([list_info])
   [ENDIF]
 </TD>
</TR>
<TR>
 <TD>
     <TABLE WIDTH=100% BORDER=1>
      <TR><TD><CODE><PRE>
       [INCLUDE list_info]
      </PRE></CODE></TD></TR>
     </TABLE>
 </TD>
</TR>
<TR>
 <TD ALIGN=CENTER><B>Fichero de configuraci�n</B>
   [IF is_listmaster]
      ([list_config])
   [ENDIF]
 </TD>
</TR><TR>
 <TD><TABLE WIDTH=100% border=1>
      <TR><TD><CODE><PRE>
        [INCLUDE list_config]
      </PRE></CODE></TD></TR>
     </TABLE>
 </TD>
</TR>
</TABLE>


