<!-- RCS Identication ; $Revision$ ; $Date$ -->
<!-- begin admin_menu.cn-gb.tpl -->
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER" COLSPAN="7">
	<FONT COLOR="[bg_color]"><b>�ʵݱ�������</b></font>
    </TD>
    </TR>
    <TR>
    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
       [IF list_conf->status=closed]
	[IF is_privileged_owner]
        <A HREF="[path_cgi]/restore_list/[list]" >
          <FONT size="-1"><b>�ָ��ʵݱ�</b></font></A>
        [ELSE]
          <FONT size="-1" COLOR="[bg_color]"><b>�ָ��ʵݱ�</b></font>
        [ENDIF]
       [ELSE]
        <A HREF="[path_cgi]/close_list/[list]" onClick="request_confirm_link('[path_cgi]/close_list/[list]', 'ȷ��Ҫ�ر� [list] �ʵݱ�?'); return false;"><FONT size=-1><b>�Ƴ��ʵݱ�</b></font></A>
    </TD>
    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
	[IF shared=none]
          <A HREF="[path_cgi]/d_admin/[list]/create" >
             <FONT size=-1><b>��������</b></font></A>
	[ELSIF shared=deleted]
          <A HREF="[path_cgi]/d_admin/[list]/restore" >
             <FONT size=-1><b>�ָ�����</b></font></A>
	[ELSIF shared=exist]
          <A HREF="[path_cgi]/d_admin/[list]/delete" >
             <FONT size=-1><b>ɾ������</b></font></A>
        [ELSE]
          <FONT size=1 color=red>
          [shared]
	[ENDIF]        
    </TD>

    [IF action=edit_list_request]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
      <FONT size="-1" COLOR="[bg_color]"><b>�༭�ʵݱ�����</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
	<A HREF="[path_cgi]/edit_list_request/[list]" >
          <FONT size="-1"><b>�༭�ʵݱ�����</b></FONT></A>
    </TD>
    [ENDIF]

    [IF action=review]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <FONT size="-1" COLOR="[bg_color]"><b>������</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR=[light_color] ALIGN=CENTER>
       [IF is_owner]
       <A HREF="[path_cgi]/review/[list]" >
       <FONT size="-1"><b>������</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    [IF action=reviewbouncing]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <FONT size="-1" COLOR="[bg_color]"><b>����</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
       [IF is_owner]
       <A HREF="[path_cgi]/reviewbouncing/[list]" >
       <FONT size="-1"><b>����</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    [IF action=modindex]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <FONT size="-1" COLOR="[bg_color]"><b>���</b></FONT>
    </TD>
    [ELSE]
       [IF is_editor]
       <TD BGCOLOR="[light_color]" ALIGN=CENTER>
         <A HREF="[path_cgi]/modindex/[list]" >
         <FONT size="-1"><b>���</b></FONT></A>
       </TD>
       [ELSE]
         <TD BGCOLOR="[light_color]" ALIGN="CENTER">
	   <FONT size="-1" COLOR="[bg_color]"><b>���</b></FONT>
	 </TD>
       [ENDIF]
    [ENDIF]

    [IF action=editfile]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <FONT size="-1" COLOR="[bg_color]"><b>����</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
       [IF is_owner]
       <A HREF="[path_cgi]/editfile/[list]" >
       <FONT size="-1"><b>����</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]
<!-- end menu_admin.cn-gb.tpl -->

