<!-- RCS Identication ; $Revision$ ; $Date$ -->

    <TABLE WIDTH="100%" BORDER=0 CELLPADDING=10>
      <TR VALIGN="top">
        <TD NOWRAP>
	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <FONT COLOR="#330099"><B>Nastaven� standardn�ch �ablon konference</B></FONT><BR>
	     <SELECT NAME="file">
	      [FOREACH f IN lists_default_files]
	        <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="Upravit">
	  </FORM>

	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <FONT COLOR="#330099"><B>Nastaven� �ablon serveru</B></FONT><BR>
	     <SELECT NAME="file">
	      [FOREACH f IN server_files]
	        <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="Upravit">
	  </FORM>
	</TD>
      </TR>
      <TR><TD><A HREF="[path_cgi]/get_pending_lists"><B>�ekaj�c� konference</B></A></TD></TR>

      <TR><TD NOWRAP>
        <FORM ACTION="[path_cgi]" METHOD="POST">
	  <INPUT NAME="email" SIZE="30" VALUE="[email]">
	  <INPUT TYPE="submit" NAME="action_search_user" VALUE="Naj�t u�ivatele">
	</FORM>     
      </TD></TR>

      <TR><TD><A HREF="[path_cgi]/view_translations"><B>Upravit �ablony</B></A></TD></TR>
      <TR>
        <TD>
<FONT COLOR="#330099"><B>Znovu sestavit HTML arch�vy</B> pomoc� <CODE>arctxt</CODE> adres��e jako vstup.
        </TD>
      </TR>
      <TR>
        <TD>
          <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="submit" NAME="action_rebuildallarc" VALUE="ALL"><BR>
	Opatrn�, vezme si hodn� strojov�ho �asu!
          </FORM>
	</TD>

    <TD ALIGN="CENTER"> 
          <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="text" NAME="list" SIZE="20">
          <INPUT TYPE="submit" NAME="action_rebuildarc" VALUE="Znovu sestavit arch�v">
          </FORM>
    </TD>


      </TR>

      <TR>
        <TD>
	  <FONT COLOR="#330099">
	  <A HREF="[path_cgi]/scenario_test">
	     <b>Modul testu sc�n��e</b>
          </A>
          </FONT>
	</TD>
      </TR>
	
    </TABLE>
