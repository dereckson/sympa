<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF file]
  [INCLUDE file]
[ELSE]

  [IF path]  
    <h2> <B> [path] k�nyvt�r tulajdons�gai</B> </h2> 
    Tulajdonos: [doc_owner] <BR>
    Utols� friss�t�s: [doc_date] <BR>
    Le�r�s: [doc_title] <BR><BR>
    <font size=+1> <A HREF="[path_cgi]/d_read/[list]/[father]"> <IMG ALIGN="bottom"  src="[father_icon]">Egy k�nyvt�rral feljebb</A></font>
    <BR>  
  [ELSE]
    <h2> <B>Megosztott k�nyvt�r tulajdons�gai</B> </h2> 
  [ENDIF]
   
  <TABLE width=100%>
  <TR BGCOLOR="--DARK_COLOR--">
   
  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="--BG_COLOR--">Dokumentumok</font></TD>
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
  
  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="--BG_COLOR--">Szerz�</font></TD>
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

  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="--BG_COLOR--">M�ret (Kb)</font></TD>
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

  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="--BG_COLOR--">Utols� friss�t�s</font></TD>
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

  <TD ALIGN="left"><font color="--BG_COLOR--">Le�r�s</font></TD> 
  <TD ALIGN="center"><font color="--BG_COLOR--">Szerkeszt</font></TD> 
  <TD ALIGN="center"><font color="--BG_COLOR--">T�r�l</font></TD>
  <TD ALIGN="center"><font color="--BG_COLOR--">Megnyit</font></TD></TR>
      
  [IF empty]
    <TR BGCOLOR="--LIGHT_COLOR--" VALIGN="top">
    <TD COLSPAN=8 ALIGN="center"> �res k�nyvt�r </TD>
    </TR>
  [ELSE]   
    [IF sort_subdirs]
      [FOREACH s IN sort_subdirs] 
        <TR BGCOLOR="--LIGHT_COLOR--">        
	<TD NOWRAP> <A HREF="[path_cgi]/d_read/[list]/[path][s->doc]/"> 
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
	<TD NOWRAP>&nbsp; [s->title]</TD>
		
	<TD>&nbsp; </TD>
	
	[IF s->edit]
	  <TD><center>
	  <FONT size=-1>
	  <A HREF="[path_cgi]/d_delete/[list]/[path][s->doc]" onClick="request_confirm_link('[path_cgi]/d_delete/[list]/[path][s->doc]', 'T�nyleg szeretn�d t�r�lni a k�vetkez�t [path][s->doc] ?'); return false;">t�r�l</A>
	  </FONT>
	  </center></TD>
	[ELSE]
	  <TD>&nbsp; </TD>
	[ENDIF]
	
	[IF s->control]
	  <TD>
	  <center>
	  <FONT size=-1>
	  <A HREF="[path_cgi]/d_control/[list]/[path][s->doc]">megnyit</A>
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
        <TR BGCOLOR="--LIGHT_COLOR--"> 
        <TD>&nbsp;
        [IF f->html]
	  <A HREF="[path_cgi]/d_read/[list]/[path][f->doc]" TARGET="html_window">
	  <IMG ALIGN=bottom BORDER=0 SRC="[f->icon]"> [f->doc] </A>
	[ELSE]
	  <A HREF="[path_cgi]/d_read/[list]/[path][f->doc]">
	  <IMG ALIGN=bottom BORDER=0 SRC="[f->icon]"> [f->doc] </A>
        [ENDIF] 
	</TD>  
	 
	<TD> 
	[IF f->author_known]
	  <A HREF="mailto:[f->author]">[f->author]</A>  
	[ELSE]
          Unknown  
        [ENDIF]
	</TD>
	 
	<TD NOWRAP> [f->size] </TD>
	<TD NOWRAP> [f->date] </TD>
	<TD NOWRAP>&nbsp; [f->title]</TD>
	 
	[IF f->edit]
	<TD>
	<center>
	<font size=-1>
	<A HREF="[path_cgi]/d_editfile/[list]/[path][f->doc]">szerkeszt</A>
	</font>
	</center>

	</TD>
	<TD>
	<center>
	<FONT size=-1>
	<A HREF="[path_cgi]/d_delete/[list]/[path][f->doc]" onClick="request_confirm_link('[path_cgi]/d_delete/[list]/[path][f->doc]', 'T�nyleg szeretn�d t�r�lni a k�vetkez�t [path][s->doc] ([f->size] Kb) ?'); return false;">t�r�l</A>
	</FONT>
	</center>
	</TD>
	[ELSE]
	  <TD>&nbsp; </TD> <TD>&nbsp; </TD>
	[ENDIF]
		 
	[IF f->control]
	  <TD> <center>
	  <font size=-1>
	  <A HREF="[path_cgi]/d_control/[list]/[path][f->doc]">megnyit</A>
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
      <B> [path] k�nyvt�r tulajdons�gai</B> <BR>
            
      <input MAXLENGTH=100 type="text" name="content" value="[description]" SIZE=50>
      </TD>
      
      <TD ALIGN="left" VALIGN="bottom">
      <input type="submit" value="Alkalmaz" name="action_d_describe">
      <INPUT TYPE="hidden" NAME="serial" VALUE="[serial_desc]">
      <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
      <INPUT TYPE="hidden" NAME="path" VALUE="[path]">     
      <INPUT TYPE="hidden" NAME="action" VALUE="d_describe">
      </TD>

      </form>
      </TR>
      [ENDIF]
   
      [IF may_control]
      <TR>   
      <form method="post" ACTION="[path_cgi]">
           
      <TD ALIGN="right" VALIGN="center">
      <B> [path] k�nyvt�r hozz�f�r�s�nek m�dos�t�sa</B> 

      </TD>
     
      <TD ALIGN="left" VALIGN="bottom">
      <input type="submit" value="   Hozz�f�r�s   " name="action_d_control">
      <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
      <INPUT TYPE="hidden" NAME="path" VALUE="[path]">     
      </TD>

      </form>
      </TR><BR>
      [ENDIF]
  
   [ENDIF] 


  [IF may_edit]
    <TR>
    <form method="post" ACTION="[path_cgi]">
    <TD ALIGN="right" VALIGN="bottom">
    [IF path]
      <B> Hozz l�tre egy �j k�nyvt�rat a(z) [path]-on bel�l</B> <BR>
    [ELSE]
      <B> Hozz l�tre egy �j k�nyvt�rat a MEGOSZTOTTban</B> <BR>
    [ENDIF]
    <input MAXLENGTH=30 type="text" name="name_doc">
    </TD>

    <TD ALIGN="left" VALIGN="bottom">
    <input type="submit" value="�j alk�nyvt�r" name="action_d_create_dir">
    <INPUT TYPE="hidden" NAME="previous_action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_create_dir">
    </TD>
    </form>
    </TR><BR>

   <TR>
   <form method="post" ACTION="[path_cgi]" ENCTYPE="multipart/form-data">
   <TD ALIGN="right" VALIGN="bottom">
   [IF path]
     <B> T�lts fel egy �j �llom�nyt a(z) [path]-ba</B><BR>
   [ELSE]
     <B> T�lts fel egy �j �llom�nyt a MEGOSZTOTTba </B><BR>
   [ENDIF]
   <input type="file" name="uploaded_file">
   </TD>

   <TD ALIGN="left" VALIGN="bottom">
   <input type="submit" value="Elk�ld" name="action_d_upload">
   <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
   <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
   <TD>
   </form> 
   </TR>
   [ENDIF]
</TABLE>
[ENDIF]
   




