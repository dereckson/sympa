<!-- RCS Identication ; $Revision$ ; $Date$ -->

<br>

<BR>
<TABLE BORDER=0 WIDTH=100% >
<TR BGCOLOR="[light_color]">
<TD>
<TABLE BORDER=0 WIDTH=100% >
<TR BGCOLOR="[light_color]">
 <TD><B>Lista neve:</B></TD><TD WIDTH=100% >[list]</TD>
</TR>
<TR BGCOLOR="[light_color]">
 <TD><B>T�mak�r: </B></TD><TD WIDTH=100%>[list_subject]</TD>
</TR>
<TR BGCOLOR="[light_color]">
 <TD NOWRAP><B>A list�t</B> [list_request_date] <b>napon</b> </TD><TD WIDTH=100%>[list_request_by] <B>k�rv�nyezte.</B> </TD>
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
<INPUT TYPE="radio" NAME="status" VALUE="closed">T�r�l &nbsp;&nbsp;
<INPUT TYPE="radio" NAME="status" VALUE="open">L�trehoz &nbsp;&nbsp;
</MENU>
</TD><TD>
<TD>
<INPUT TYPE="submit" NAME="action_install_pending_list" VALUE="Ment�s">
<INPUT TYPE="chechkbox" NAME="notify" CHECKED>listagazda �rtes�t�se
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
   <B>Inform�ci�s �llom�ny</B> 
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
 <TD ALIGN=CENTER><B>Konfigur�ci�s �llom�ny</B>
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


