<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF file]
  [INCLUDE file]
[ELSE]

  [IF path]  
    <h2><B><IMG SRC="/icons/folder.open.png"> [path] </B> </h2> 
    <A HREF="[path_cgi]/d_editfile/[list]/[escaped_path]">�޸�</A> | 
    <A HREF="[path_cgi]/d_delete/[list]/[escaped_path]" onClick="request_confirm_link('[path_cgi]/d_delete/[list]/[escaped_path]', 'ȷ��Ҫɾ�� [path] ?'); return false;">ɾ��</A> |
    <A HREF="[path_cgi]/d_control/[list]/[escaped_path]">��ȡ</A><BR>

    ������: [doc_owner] <BR>
    ������: [doc_date] <BR>
    [IF doc_title]
    ����: [doc_title] <BR><BR>
    [ENDIF]
    <font size=+1> <A HREF="[path_cgi]/d_read/[list]/[father]"> <IMG ALIGN="bottom"  src="[father_icon]"> ת����һ��Ŀ¼</A></font>
    <BR>  
  [ELSE]
    <h2> <B> �ļ��� SHARED ������ </B> </h2> 
  [ENDIF]
   
  <TABLE width=100%>
  <TR BGCOLOR="[dark_color]">
   
  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="[bg_color]">�ĵ�</font></TD>
  [IF  order_by<>order_by_doc]  
    <TD ALIGN="right">
    <form method="post" ACTION="[path_cgi]">  
    <INPUT ALIGN="top"  type="image" src="[sort_icon]" WIDTH=15 HEIGHT=15 name="����������">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="order" VALUE="order_by_doc">
    </form>
    </TD>
  [ENDIF]	
  </TR></TABLE>
  </th>
  
  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="[bg_color]">����</font></TD>
  [IF  order_by<>order_by_author]  
    <TD ALIGN="right">
    <form method="post" ACTION="[path_cgi]">  
    <INPUT ALIGN="top"  type="image" src="[sort_icon]" WIDTH=15 HEIGHT=15 name="����������">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="order" VALUE="order_by_author">
    </form>	
    </TD>
  [ENDIF]
  </TR></TABLE>
  </th> 

  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="[bg_color]">��С(KB)</font></TD>
  [IF order_by<>order_by_size] 
    <TD ALIGN="right">
    <form method="post" ACTION="[path_cgi]">
    <INPUT ALIGN="top"  type="image" src="[sort_icon]" WIDTH=15 HEIGHT=15 name="����С����">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="order" VALUE="order_by_size">
    </form>
    </TD>
  [ENDIF]
  </TR></TABLE>   
  </th> 

  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="[bg_color]">������</font></TD>
  [IF order_by<>order_by_date]
    <TD ALIGN="right">
    <form method="post" ACTION="[path_cgi]">
    <INPUT ALIGN="top"  type="image" src="[sort_icon]" WIDTH=15 HEIGHT=15 name="����������">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="order" VALUE="order_by_date">
    </form>
    </TD>
  [ENDIF]
  </TR></TABLE>  
  </th> 

  <th ALIGN="left"><font color="[bg_color]">����</font></th> 
  <th ALIGN="center"><font color="[bg_color]">�༭</font></th> 
  <th ALIGN="center"><font color="[bg_color]">ɾ��</font></th>
  <th ALIGN="center"><font color="[bg_color]">��ȡ</font></th></TR>
      
  [IF empty]
    <TR BGCOLOR="[light_color]" VALIGN="top">
    <TD COLSPAN=8 ALIGN="center"> ���ļ��� </TD>
    </TR>
  [ELSE]   
    [IF sort_subdirs]
      [FOREACH s IN sort_subdirs] 
        <TR BGCOLOR="[light_color]">        
	<TD NOWRAP> <A HREF="[path_cgi]/d_read/[list]/[escaped_path][s->escaped_doc]/"> 
	<IMG ALIGN=bottom BORDER=0 SRC="[s->icon]" ALT="[s->title]"> [s->doc]</A></TD>
	<TD>
	[IF s->author_known] 
	  <A HREF="mailto:[s->author]">[s->author]</A>  
        [ELSE]
	   δ֪
	[ENDIF]
	</TD>	    
	<TD>&nbsp;</TD>
	<TD NOWRAP> [s->date] </TD>
		
	[IF s->edit]

	<TD><center>
	<font size=-1>
	<A HREF="[path_cgi]/d_editfile/[list]/[escaped_path][s->escaped_doc]">�޸�</A>
	</font>
	</center></TD>

	  <TD><center>
          <FONT size=-1>
          <A HREF="[path_cgi]/d_delete/[list]/[escaped_path][s->escaped_doc]" onClick="request_confirm_link('[path_cgi]/d_delete/[list]/[escaped_path][s->escaped_doc]', '��ȷ��Ҫɾ�� [path][s->doc] �� ?'); return false;">ɾ��</A>
	  </FONT>
	  </center></TD>
	[ELSE]
	  <TD>&nbsp; </TD>
	  <TD>&nbsp; </TD>
	[ENDIF]
	
	[IF s->control]
	  <TD>
	  <center>
	  <FONT size=-1>
	  <A HREF="[path_cgi]/d_control/[list]/[escaped_path][s->escaped_doc]">��ȡ</A>
	  </font>
	  </center>
	  </TD>	 
	[ELSE]
	  <TD>&nbsp; </TD>
	[ENDIF]
      </TR>
      [END] 
    [ENDIF]

    [IF sort_files]
      [FOREACH f IN sort_files]
        <TR BGCOLOR="[light_color]"> 
        <TD>&nbsp;
        [IF f->html]
	  <A HREF="[path_cgi]/d_read/[list]/[escaped_path][f->escaped_doc]" TARGET="html_window">
	  <IMG ALIGN=bottom BORDER=0 SRC="[f->icon]" ALT="[f->title]"> [f->doc] </A>
	[ELSIF f->url]
	  <A HREF="[f->url]" TARGET="html_window">
	  <IMG ALIGN=bottom BORDER=0 SRC="[f->icon]" ALT="[f->title]"> [f->anchor] </A>
	[ELSE]
	  <A HREF="[path_cgi]/d_read/[list]/[escaped_path][f->escaped_doc]">
	  <IMG ALIGN=bottom BORDER=0 SRC="[f->icon]" ALT="[f->title]"> [f->doc] </A>
        [ENDIF] 
	</TD>  
	 
	<TD> 
	[IF f->author_known]
	  <A HREF="mailto:[f->author]">[f->author]</A>  
	[ELSE]
          δ֪ 
        [ENDIF]
	</TD>
	 
	<TD NOWRAP>&nbsp;
	[IF !f->url]
	[f->size] 
	[ENDIF]
	</TD>
	<TD NOWRAP> [f->date] </TD>
	 
	[IF f->edit]
	<TD>
	<center>
	<font size=-1>
	<A HREF="[path_cgi]/d_editfile/[list]/[escaped_path][f->escaped_doc]">edit</A>
	</font>
	</center>

	</TD>
	<TD>
	<center>
	<FONT size=-1>
	<A HREF="[path_cgi]/d_delete/[list]/[escaped_path][f->escaped_doc]" onClick="request_confirm_link('[path_cgi]/d_delete/[list]/[escaped_path][f->escaped_doc]', '��ȷ��Ҫɾ�� [path][s->doc] ([f->size] Kb) ��?'); return false;">ɾ��</A>
	</FONT>
	</center>
	</TD>
	[ELSE]
	  <TD>&nbsp; </TD> <TD>&nbsp; </TD>
	[ENDIF]
		 
	[IF f->control]
	  <TD> <center>
	  <form method="post" ACTION="[path_cgi]">
	  <font size=-1>
	  <A HREF="[path_cgi]/d_control/[list]/[escaped_path][f->escaped_doc]">��ȡ</A>
	  </font>
	  </center></TD>
	[ELSE]
	<TD>&nbsp; </TD>
	[ENDIF]
	</TR>
      [END] 
    [ENDIF]
  [ENDIF]
  </TABLE>	        
 
  <HR> 
<TABLE CELLSPACING=20>
   
  [IF may_edit]
    <TR>
    <form method="post" ACTION="[path_cgi]">
    <TD ALIGN="right" VALIGN="bottom">
    [IF path]
      <B> ���ļ��� [path] �ｨ�����ļ���</B> <BR>
    [ELSE]
      <B> ���ļ��� SHARED �ｨ�����ļ���</B> <BR>
    [ENDIF]
    <input MAXLENGTH=30 type="text" name="name_doc">
    </TD>

    <TD ALIGN="left" VALIGN="bottom">
    <input type="submit" value="�����µ���Ŀ¼" name="action_d_create_dir">
    <INPUT TYPE="hidden" NAME="previous_action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="type" VALUE="directory">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_create_dir">
    </TD>
    </form>
    </TR>

    <TR>
    <form method="post" ACTION="[path_cgi]">
    <TD ALIGN="right" VALIGN="bottom">
      <B> �����µ��ļ�</B> <BR>
    <input MAXLENGTH=30 type="text" name="name_doc">
    </TD>

    <TD ALIGN="left" VALIGN="bottom">
    <input type="submit" value="�����µ��ļ�" name="action_d_create_dir">
    <INPUT TYPE="hidden" NAME="previous_action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="type" VALUE="file">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_create_dir">
    </TD>
    </form>
    </TR>

    <TR>
    <FORM METHOD="POST" ACTION="[path_cgi]">
    <TD ALIGN="right" VALIGN="center">
    <B>�����µ���ǩ</B><BR>
    URL <input MAXLENGTH=100 SIZE="25" type="text" name="url"><BR>
    title <input MAXLENGTH=100 SIZE="20" type="text" name="name_doc">
    </TD>

    <TD ALIGN="left" VALIGN="bottom">
    <input type="submit" value="����" name="action_d_savefile">
    <INPUT TYPE="hidden" NAME="previous_action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_savefile">
    </TD>
    </FORM>
    </TR>


   <TR>
   <form method="post" ACTION="[path_cgi]" ENCTYPE="multipart/form-data">
   <TD ALIGN="right" VALIGN="bottom">
   [IF path]
     <B> �ϴ�һ���ļ����ļ��� [path] �� </B><BR>
   [ELSE]
     <B> �ϴ�һ���ļ����ļ��� SHARED �� </B><BR>
   [ENDIF]
   <input type="file" name="uploaded_file">
   </TD>

   <TD ALIGN="left" VALIGN="bottom">
   <input type="submit" value="����" name="action_d_upload">
   <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
   <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
   <TD>
   </form> 
   </TR>
   [ENDIF]
</TABLE>
[ENDIF]
   



