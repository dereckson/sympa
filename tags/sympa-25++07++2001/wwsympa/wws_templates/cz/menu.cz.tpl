<!-- RCS Identication ; $Revision$ ; $Date$ -->

<!-- begin menu.tpl -->
<TABLE CELLPADDING="0" CELLSPACING="0" WIDTH="100%" BORDER="0"><TR><TD>
<TABLE CELLPADDING="2" CELLSPACING="2" WIDTH="100%" BORDER="0">
  <TR ALIGN=center BGCOLOR="#330099">
  [IF auth_method=smime]
  <TD bgcolor="#ffffff">
<A HREF="[path_cgi]/show_cert" onClick="winhelp=window.open('','wws_help','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,copyhistory=no,width=600,height=320');winlogin.focus()" TARGET="wws_help"><IMG SRC="[icons_url]/locked.gif" align="center" alt="security info" border=0></A>
  [ELSE]
  <TD>
  <TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="2">
     <TR> 
  [IF user->email]
  [IF auth_method=md5]
      <TD NOWRAP BGCOLOR="#ccccff" ALIGN="center"> 
     [IF referer]
      <A HREF="[path_cgi]/logout/referer/[referer]" >
     [ELSE]
      <A HREF="[path_cgi]/logout/[action]/[list]" >
     [ENDIF]
     <FONT SIZE=-1><B>Odhl�en�</B></FONT></A>
     </TD>
  [ELSE]
     <TD NOWRAP BGCOLOR="#ffffff" ALIGN="center"><IMG SRC="[icons_url]/locked.gif" align="center" alt="https"></TD>
  [ENDIF]
  [ELSE]
      <TD NOWRAP BGCOLOR="#ccccff" ALIGN="center"> 
     [IF referer]
      <A HREF="[path_cgi]/nomenu/loginrequest/referer/[referer]"
     [ELSE]
      <A HREF="[path_cgi]/nomenu/loginrequest/[action]/[list]"
     [ENDIF]
       onClick="window.open('','wws_login','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,copyhistory=no,width=550,height=300')" TARGET="wws_login">
       <FONT SIZE=-1><B>P�ihl�en�</B></FONT></A>
      </TD>
  [ENDIF]
    </TR>
  </TABLE>
  [ENDIF]
</TD></TR>
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
        <FONT SIZE=-1 COLOR=#ffffff ><B>Vytvo�en� konference</B></FONT>
    </TD>
   [ELSE]
    <TD NOWRAP BGCOLOR="#ccccff"  ALIGN="center">
	 <A HREF="[path_cgi]/create_list_request" ><FONT SIZE=-1><B>Vytvo�en� konference</B></FONT></A>
    </TD>
   [ENDIF]
  [ENDIF]

  [IF is_listmaster]
   [IF action=serveradmin]
    <TD NOWRAP BGCOLOR="#3366cc" ALIGN="center">
        <FONT SIZE=-1 COLOR=#ffffff ><B>Sympa admin</B></FONT>
    </TD>
   [ELSE]
    <TD NOWRAP BGCOLOR="#ccccff"  ALIGN="center">
	 <A HREF="[path_cgi]/serveradmin" ><font size=-1><B>Sympa admin</B></FONT></A>
    </TD>
   [ENDIF]
  [ENDIF]

  [IF user->email]

  [IF action=pref]
  <TD NOWRAP BGCOLOR="#3366cc"  ALIGN="center">
      <FONT SIZE=-1 COLOR=#ffffff ><B>Nastaven�</B></FONT>
  </TD>
  [ELSE]
  <TD NOWRAP BGCOLOR="#ccccff">
      <A HREF="[path_cgi]/pref/[action]/[list]" ><FONT SIZE=-1><B>Nastaven�</B></FONT></A>
  </TD>
  [ENDIF]

  [IF action=which]
  <TD NOWRAP BGCOLOR="#3366cc" ALIGN="center">
      <FONT SIZE=-1 COLOR=#ffffff ><B>P�ihl�en� konference</B></FONT>
  </TD>
  [ELSE]
  <TD NOWRAP BGCOLOR="#ccccff" ALIGN="center">
      <A HREF="[path_cgi]/which" ><FONT SIZE=-1><B>P�ihl�en� konference</B></FONT></A>
   </TD>
   [ENDIF]
  
  [ELSE]
  <TD NOWRAP BGCOLOR="#ccccff" ALIGN="center">
      <FONT SIZE=-1 COLOR=#ffffff ><B>Nastaven�</B></FONT>
  </TD>
  <TD NOWRAP BGCOLOR="#ccccff" ALIGN="center">
      <FONT SIZE=-1 COLOR="#ffffff"><B>P�ihl�en� konference</B></FONT>
  </TD>
  [ENDIF]

  [IF action=home]
  <TD NOWRAP BGCOLOR="#3366cc" ALIGN="center"><FONT SIZE=-1 COLOR=#ffffff><B>N�vrat na za��tek</B></FONT></TD>
  [ELSE]
  <TD NOWRAP BGCOLOR="#ccccff" ALIGN="center">
      <A HREF="[path_cgi]/"><FONT SIZE=-1><B>N�vrat na za��tek</B></FONT></A>
  </TD>
  [ENDIF]

  [IF action=help]
  <TD NOWRAP BGCOLOR="#3366cc" ALIGN="center"><FONT SIZE=-1 COLOR=#ffffff><B>N�pov�da</B></FONT></TD>
  [ELSE]
  <TD NOWRAP BGCOLOR="#ccccff" ALIGN="center">
      <A HREF="[path_cgi]/help" ><FONT SIZE=-1><B>N�pov�da</B></FONT></A>
  </TD>
  [ENDIF]
</TR>
</TABLE>
</TD></TR></TABLE>
</TD></TR></TABLE>
<!-- end menu.tpl -->