<!-- begin menu.it.tpl -->
<TABLE CELLPADDING="0" CELLSPACING="0" WIDTH="100%" BORDER="0"><TR><TD>
<TABLE CELLPADDING="2" CELLSPACING="2" WIDTH="100%" BORDER="0">
  <TR ALIGN=center BGCOLOR="#330099">
  [IF auth_method=smime]
  <TD bgcolor="#ffffff">
     <IMG SRC="[icons_url]/locked.gif" align="center" alt="https">
  [ELSE]
  <TD>
  <TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="2">
     <TR> 
  [IF user->email]
  [IF auth_method=md5]
      <TD NOWRAP BGCOLOR="#ccccff" ALIGN="center"> 
     [IF referer]
      <A HREF="[path_cgi]/logout/referer/[referer]" STYLE="TEXT-DECORATION: NONE">
     [ELSE]
      <A HREF="[path_cgi]/logout/[action]/[list]" STYLE="TEXT-DECORATION: NONE">
     [ENDIF]
     <FONT SIZE=-1><B>Logout</B></FONT></A>
     </TD>
  [ELSE]
     <TD NOWRAP BGCOLOR="#ffffff" ALIGN="center"><IMG SRC="[icons_url]/locked.gif" align="center" alt="https"></TD>
  [ENDIF]
  [ELSE]
      <TD NOWRAP BGCOLOR="#ccccff" ALIGN="center"> 
     [IF referer]
      <A HREF="[path_cgi]/nomenu/loginrequest/referer/[referer]" STYLE="TEXT-DECORATION: NONE"
     [ELSE]
      <A HREF="[path_cgi]/nomenu/loginrequest/[action]/[list]" STYLE="TEXT-DECORATION: NONE"
     [ENDIF]
onClick="window.open('','wws_login','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,copyhistory=no,width=450,height=300')" TARGET="wws_login">
	 <FONT SIZE=-1><B>Login</B></FONT></A>
         </TD>
  [ENDIF]
    </TR>
  </TABLE>
  [ENDIF]
</TR>
</TABLE>


</TD>
<TD WIDTH=100% BGCOLOR="#ffffff">&nbsp;</TD>
<TD>

<TABLE CELLPADDING=0 CELLSPACING=0 WIDTH="100%" BORDER=0>
  <TR ALIGN=center BGCOLOR="#330099"><TD>
  <TABLE WIDTH="100%" BORDER=0 CELLSPACING=2 CELLPADDING=2>
     <TR> 
  [IF may_create_list]
   [IF action=create_list_request]
    <TD NOWRAP BGCOLOR="#3366cc" ALIGN="center">
        <FONT SIZE=-1 COLOR=#ffffff ><B>Crea una lista</B></FONT>
    </TD>
   [ELSE]
    <TD NOWRAP BGCOLOR="#ccccff"  ALIGN="center">
	 <A HREF="[path_cgi]/create_list_request" STYLE="TEXT-DECORATION: NONE"><FONT SIZE=-1><B>Crea una lista</B></FONT></A>
    </TD>
   [ENDIF]
  [ENDIF]

  [IF is_listmaster]
   [IF action=serveradmin]
    <TD NOWRAP BGCOLOR="#3366cc" ALIGN="center">
        <FONT SIZE=-1 COLOR=#ffffff ><B>Amministra Sympa</B></FONT>
    </TD>
   [ELSE]
    <TD NOWRAP BGCOLOR="#ccccff"  ALIGN="center">
	 <A HREF="[path_cgi]/serveradmin" STYLE="TEXT-DECORATION: NONE"><font size=-1><B>Amministra Sympa</B></FONT></A>
    </TD>
   [ENDIF]
  [ENDIF]

  [IF user->email]

  [IF action=pref]
  <TD NOWRAP BGCOLOR="#3366cc"  ALIGN="center">
      <FONT SIZE=-1 COLOR=#ffffff ><B>Preferenze</B></FONT>
  </TD>
  [ELSE]
  <TD NOWRAP BGCOLOR="#ccccff">
      <A HREF="[path_cgi]/pref" STYLE="TEXT-DECORATION: NONE"><FONT SIZE=-1><B>Preferenze</B></FONT></A>
  </TD>
  [ENDIF]

  [IF action=which]
  <TD NOWRAP BGCOLOR="#3366cc" ALIGN="center">
      <FONT SIZE=-1 COLOR=#ffffff ><B>Le tue mailing list</B></FONT>
  </TD>
  [ELSE]
  <TD NOWRAP BGCOLOR="#ccccff" ALIGN="center">
      <A HREF="[path_cgi]/which" STYLE="TEXT-DECORATION: NONE"><FONT SIZE=-1><B>Le mie mailing list</B></FONT></A>
   </TD>
   [ENDIF]
  
  [ELSE]
  <TD NOWRAP BGCOLOR="#ccccff" ALIGN="center">
      <FONT SIZE=-1 COLOR=#ffffff ><B>Pref</B></FONT>
  </TD>
  <TD NOWRAP BGCOLOR="#ccccff" ALIGN="center">
      <FONT SIZE=-1 COLOR="#ffffff"><B>Le mie mailing list</B></FONT>
  </TD>
  [ENDIF]

  [IF action=home]
  <TD NOWRAP BGCOLOR="#3366cc" ALIGN="center"><FONT SIZE=-1 COLOR=#ffffff><B>Principale</B></FONT></TD>
  [ELSE]
  <TD NOWRAP BGCOLOR="#ccccff" ALIGN="center">
      <A HREF="[path_cgi]/" STYLE="TEXT-DECORATION: NONE"><FONT SIZE=-1><B>Principale</B></FONT></A>
  </TD>
  [ENDIF]

  [IF action=help]
  <TD NOWRAP BGCOLOR="#3366cc" ALIGN="center"><FONT SIZE=-1 COLOR=#ffffff><B>Aiuto</B></FONT></TD>
  [ELSE]
  <TD NOWRAP BGCOLOR="#ccccff" ALIGN="center">
      <A HREF="[path_cgi]/help" STYLE="TEXT-DECORATION: NONE"><FONT SIZE=-1><B>Aiuto</B></FONT></A>
  </TD>
  [ENDIF]
</TR>
</TABLE>
</TD></TR></TABLE>
</TD></TR></TABLE>
<!-- end menu.it.tpl -->




