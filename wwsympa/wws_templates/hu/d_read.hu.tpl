<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF file]
  [INCLUDE file]
[ELSE]

  [IF path]  
    <h2> <B><IMG SRC="[icons_url]/folder.open.png">[path]</B> </h2> 
   <A HREF="[path_cgi]/d_editfile/[list]/[escaped_path]">szerkeszt</A>
   <A HREF="[path_cgi]/d_delete/[list]/[escaped_path]" onClick="request_confirm_link('[path_cgi]/d_delete/[list]/[escaped_path]', 'T�nyleg akarod t�r�lni a(z) [path] k�nyvt�rat?'); return false;">t�r�l</A>
   <A HREF="[path_cgi]/d_control/[list]/[escaped_path]">hozz�f�r�s</A><BR>
    Tulajdonos: [doc_owner] <BR>
    Utols� friss�t�s: [doc_date] <BR>
  [IF doc_title]
    Le�r�s: [doc_title] <BR><BR>
  [ENDIF]
  
    <font size=+1> <A HREF="[path_cgi]/d_read/[list]/[escaped_father]"> <IMG ALIGN="bottom"  src="[father_icon]">Egy k�nyvt�rral feljebb</A></font>
    <BR>  
  [ELSE]
    <h2> <B>Megosztott k�nyvt�r tartalma</B> </h2> 
  [ENDIF]
   
  <TABLE width=100%>
  <TR BGCOLOR="[dark_color]">
   
  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="[bg_color]">Dokumentumok</font></TD>
  [IF  order_by<>order_by_doc]  
    <TD ALIGN="right">
    <form method="post" ACTION="[path_cgi]">  
    <INPUT ALIGN="top"  type="image" src="[sort_icon]" WIDTH=15 HEIGHT=15 name="N�vsorban">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="order" VALUE="order_by_doc">
    </form>
    </TD>
  [ENDIF]	
  </TR></TABLE>
  </th>
  
  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="[bg_color]">Szerz�</font></TD>
  [IF  order_by<>order_by_author]  
    <TD ALIGN="right">
    <form method="post" ACTION="[path_cgi]">  
    <INPUT ALIGN="top"  type="image" src="[sort_icon]" WIDTH=15 HEIGHT=15 name="Szerz� szerint">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="order" VALUE="order_by_author">
    </form>	
    </TD>
  [ENDIF]
  </TR></TABLE>
  </th> 

  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="[bg_color]">M�ret (Kb)</font></TD>
  [IF order_by<>order_by_size] 
    <TD ALIGN="right">
    <form method="post" ACTION="[path_cgi]">
    <INPUT ALIGN="top"  type="image" src="[sort_icon]" WIDTH=15 HEIGHT=15 name="M�ret szerint">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="order" VALUE="order_by_size">
    </form>
    </TD>
  [ENDIF]
  </TR></TABLE>   
  </th> 

  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="[bg_color]">Utols� m�dos�t�s</font></TD>
  [IF order_by<>order_by_date]
    <TD ALIGN="right">
    <form method="post" ACTION="[path_cgi]">
    <INPUT ALIGN="top"  type="image" src="[sort_icon]" WIDTH=15 HEIGHT=15 name="D�tum szerint">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="order" VALUE="order_by_date">
    </form>
    </TD>
  [ENDIF]
  </TR></TABLE>  
  </th> 

  <TD ALIGN="center"><font color="[bg_color]">Szerkeszt</font></TD> 
  <TD ALIGN="center"><font color="[bg_color]">T�r�l</font></TD>
  <TD ALIGN="center"><font color="[bg_color]">Hozz�f�r�s</font></TD></TR>
      
  [IF empty]
    <TR BGCOLOR="[light_color]" VALIGN="top">
    <TD COLSPAN=8 ALIGN="center"> �res k�nyvt�r </TD>
    </TR>
  [ELSE]   
    [IF sort_subdirs]
      [FOREACH s IN sort_subdirs] 
        <TR BGCOLOR="[light_color]">        
	<TD NOWRAP> <A HREF="[path_cgi]/d_read/[list]/[escaped_path][s->escaped_doc]/"> 
	<IMG ALIGN=bottom BORDER=0 SRC="[s->icon]"> [s->doc]</A></TD>
	<TD>
	[IF s->author_known] 
	  <A HREF="mailto:[s->author]">[s->author]</A>  
        [ELSE]
	   Unknown 
	[ENDIF]
	</TD>	    
	<TD>&nbsp;</TD>
	<TD NOWRAP> [s->date] </TD>
	
	[IF s->edit]
	  <TD><center>
	  <FONT size=-1>
	  <A HREF="[path_cgi]/d_editfile/[list]/[escaped_path][s->escaped_doc]">szerkeszt</A>
          </font>

          </center></TD>
	  <TD><center>
	  <A HREF="[path_cgi]/d_delete/[list]/[escaped_path][s->escaped_doc]" onClick="request_confirm_link('[path_cgi]/d_delete/[list]/[escaped_path][s->escaped_doc]', 'T�nyleg szeretn�d t�r�lni a k�vetkez�t: [path][s->doc] ?'); return false;">t�r�l</A>
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
	  <A HREF="[path_cgi]/d_control/[list]/[escaped_path][s->escaped_doc]">megnyit</A>
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
          Unknown  
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
	<A HREF="[path_cgi]/d_editfile/[list]/[escaped_path][f->escaped_doc]">szerkeszt</A>
	</font>
	</center>

	</TD>
	<TD>
	<center>
	<FONT size=-1>
	<A HREF="[path_cgi]/d_delete/[list]/[escaped_path][f->escaped_doc]" onClick="request_confirm_link('[path_cgi]/d_delete/[list]/[escaped_path][f->escaped_doc]', 'T�nyleg szeretn�d t�r�lni a k�vetkez�t [path][s->doc] ([f->size] Kb) ?'); return false;">t�r�l</A>
	</FONT>
	</center>
	</TD>
	[ELSE]
	  <TD>&nbsp; </TD> <TD>&nbsp; </TD>
	[ENDIF]
		 
	[IF f->control]
	  <TD> <center>
	  <font size=-1>
	  <A HREF="[path_cgi]/d_control/[list]/[escaped_path][f->escaped_doc]">megnyit</A>
	  </font>
	  </center></TD>
	[ELSE]
	<TD>&nbsp; </TD>
	[ENDIF]
	</TD>
	</TR>
      [END] 
    [ENDIF]
  [ENDIF]
  </TABLE>	        
 
  <HR> 
<TABLE CELLSPACING=20>
   
   [IF path]
         
      [IF may_edit]
      <TR>
      <form method="post" ACTION="[path_cgi]">
      <TD ALIGN="right" VALIGN="bottom">
      [IF path]
      <B> Hozzon l�tre egy �j k�nyvt�rat a(z) [path] k�nyvt�ron bel�l</B> <BR>
       
      [ELSE]

      <B> �j k�nyvt�r l�trehoz�sa a MEGOSZTOTT K�NYVT�RON bel�l </B><BR>
      [ENDIF]
      <input MAXLENGTH=30 type="text" name="name_doc">
      </TD>
      
      <TD ALIGN="left" VALIGN="bottom">
      <input type="submit" value="�j k�nyvt�r l�trehoz�sa" name="action_d_create_dir">
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
	<B>�j �llom�ny l�trehoz�sa</B> <BR>
        <input MAXLENGTH=30 type="text" name="name_doc">

      </TD>
     
      <TD ALIGN="left" VALIGN="bottom">
      <input type="submit" value="�j �llom�ny l�trehoz�sa" name="action_d_create_dir">
      <INPUT TYPE="hidden" NAME="previous_action" VALUE="d_read">
      <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
      <INPUT TYPE="hidden" NAME="path" VALUE="[path]">     
      <INPUT TYPE="hidden" NAME="type" VALUE="file">
      <INPUT TYPE="hidden" NAME="action" VALUE="d_create_dir">
      </TD>

      </form>
      </TR><BR>
      [ENDIF]
  
   [ENDIF] 

    <TR>
    <form method="post" ACTION="[path_cgi]">
    <TD ALIGN="right" VALIGN="center">
    <B>K�nyvjelz� hozz�ad�sa</B><BR>    
     URL <input MAXLENGTH=100 SIZE="25" type="text" name="url"><BR>
     megnevez�s <input MAXLENGTH=100 SIZE="20" type="text" name="name_doc">
    </TD>

    <TD ALIGN="left" VALIGN="bottom">
    <input type="submit" value="Hozz�ad" name="action_d_savefile">
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
     <B> �j �llom�ny felt�lt�se a(z) [path] k�nyvt�rba</B><BR>
   [ELSE]
     <B> �j �llom�ny felt�lt�se a MEGOSZTOTT K�NYVT�Rba </B><BR>
   [ENDIF]
   <input type="file" name="uploaded_file">
   </TD>

   <TD ALIGN="left" VALIGN="bottom">
   <input type="submit" value="Felt�lt" name="action_d_upload">
   <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
   <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
   <TD>
   </form> 
   </TR>
   [ENDIF]
</TABLE>
[ENDIF]
   




