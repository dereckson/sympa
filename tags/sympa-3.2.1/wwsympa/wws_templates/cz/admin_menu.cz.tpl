<!-- RCS Identication ; $Revision$ ; $Date$ -->

<!-- begin admin_menu.us.tpl -->
    <TD BGCOLOR="#3366cc" ALIGN="CENTER" COLSPAN="7">
	<FONT COLOR="#ffffff"><b>Panel spr�vy konference</b></font>
    </TD>
    </TR>
    <TR>
    <TD BGCOLOR="#ccccff" ALIGN="CENTER">
       [IF list_conf->status=closed]
	[IF is_listmaster]
        <A HREF="[base_url][path_cgi]/restore_list/[list]" >
          <FONT size="-1"><b>Obnovit konferenci</b></font></A>
        [ELSE]
          <FONT size="-1" COLOR="#ffffff"><b>Obnovit konferenci</b></font>
        [ENDIF]
       [ELSE]
        <A HREF="[base_url][path_cgi]/close_list/[list]" onClick="request_confirm_link('[path_cgi]/close_list/[list]', 'Opravdu chcete uzav��t konferenci [list] ?'); return false;"><FONT size=-1><b>Uzav��t konferenci</b></font></A>
       [ENDIF]
    </TD>
    <TD BGCOLOR="#ccccff" ALIGN="CENTER">
	[IF shared=none]
          <A HREF="[base_url][path_cgi]/d_admin/[list]/create" >
             <FONT size=-1><b>Vytvo�it sd�len� adres��</b></font></A>
	[ELSIF shared=deleted]
          <A HREF="[base_url][path_cgi]/d_admin/[list]/restore" >
             <FONT size=-1><b>Obnovit sd�len� adres��</b></font></A>
	[ELSIF shared=exist]
          <A HREF="[base_url][path_cgi]/d_admin/[list]/delete" >
             <FONT size=-1><b>Vymazat sd�len� adres��</b></font></A>
        [ELSE]
          <FONT size=1 color=red>
          [shared]
	[ENDIF]        
    </TD>

    [IF action=edit_list_request]
    <TD BGCOLOR="#3366cc" ALIGN="CENTER">
      <FONT size="-1" COLOR="#ffffff"><b>Upravit konfiguraci konference</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="#ccccff" ALIGN="CENTER">
	<A HREF="[path_cgi]/edit_list_request/[list]" >
          <FONT size="-1"><b>Upravit konfiguraci konference</b></FONT></A>
    </TD>
    [ENDIF]

    [IF action=review]
    <TD BGCOLOR="#3366cc" ALIGN="CENTER">
       <FONT size="-1" COLOR="#ffffff"><b>�lenov�</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR=#ccccff ALIGN=CENTER>
       [IF is_owner]
       <A HREF="[base_url][path_cgi]/review/[list]" >
       <FONT size="-1"><b>�lenov�</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    [IF action=reviewbouncing]
    <TD BGCOLOR="#3366cc" ALIGN="CENTER">
       <FONT size="-1" COLOR="#ffffff"><b>Vr�cen� zpr�vy</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="#ccccff" ALIGN="CENTER">
       [IF is_owner]
       <A HREF="[base_url][path_cgi]/reviewbouncing/[list]" >
       <FONT size="-1"><b>Vr�cen� zpr�vy</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    [IF action=modindex]
    <TD BGCOLOR="#3366cc" ALIGN="CENTER">
       <FONT size="-1" COLOR="#ffffff"><b>Moderov�n�</b></FONT>
    </TD>
    [ELSE]
       [IF is_editor]
       <TD BGCOLOR="#ccccff" ALIGN=CENTER>
         <A HREF="[base_url][path_cgi]/modindex/[list]" >
         <FONT size="-1"><b>Moderov�n�</b></FONT></A>
       </TD>
       [ELSE]
         <TD BGCOLOR="#ccccff" ALIGN="CENTER">
	   <FONT size="-1" COLOR="#ffffff"><b>Moderov�n�</b></FONT>
	 </TD>
       [ENDIF]
    [ENDIF]

    [IF action=editfile]
    <TD BGCOLOR="#3366cc" ALIGN="CENTER">
       <FONT size="-1" COLOR="#ffffff"><b>�pravy</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="#ccccff" ALIGN="CENTER">
       [IF is_owner]
       <A HREF="[base_url][path_cgi]/editfile/[list]" >
       <FONT size="-1"><b>�pravy</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]
<!-- end menu_admin.tpl -->
