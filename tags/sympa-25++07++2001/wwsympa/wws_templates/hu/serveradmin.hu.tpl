<!-- RCS Identication ; $Revision$ ; $Date$ -->

    <TABLE WIDTH="100%" BORDER=0 CELLPADDING=10>
      <TR VALIGN="top">
        <TD NOWRAP>
	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <FONT COLOR="--DARK_COLOR--"><B>A lista alap�rtelmezett sablonjainak be�ll�t�sa</B></FONT><BR>
	     <SELECT NAME="file">
	      [FOREACH f IN lists_default_files]
	        <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="Szerkeszt�s">
	  </FORM>

	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <FONT COLOR="--DARK_COLOR--"><B>A rendszer sablonjainak be�ll�t�sa</B></FONT><BR>
	     <SELECT NAME="file">
	      [FOREACH f IN server_files]
	        <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="Szerkeszt�s">
	  </FORM>
	</TD>
      </TR>
      <TR><TD><A HREF="[path_cgi]/get_pending_lists"><B>F�gg� list�k</B></A></TD></TR>

      <TR><TD NOWRAP>
        <FORM ACTION="[path_cgi]" METHOD="POST">
	  <INPUT NAME="email" SIZE="30" VALUE="[email]">
	  <INPUT TYPE="submit" NAME="action_search_user" VALUE="Tag keres�se">
	</FORM>     
      </TD></TR>

      <TR><TD><A HREF="[path_cgi]/view_translations"><B>Sablonok m�dos�t�sa</B></A></TD></TR>
      <TR>
        <TD>
<FONT COLOR="--DARK_COLOR--"><B>HTML arch�vum friss�t�se</B> az <CODE>arctxt</CODE> k�nyvt�r felhaszn�l�s�val.
        </TD>
      </TR>
      <TR>
        <TD>
          <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="submit" NAME="action_rebuildallarc" VALUE="Mind"><BR>
	Csak �vatosan, mivel nagyon g�pig�nyes!
          </FORM>
	</TD>

    <TD ALIGN="CENTER"> 
          <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="text" NAME="list" SIZE="20">
          <INPUT TYPE="submit" NAME="action_rebuildarc" VALUE="Arch�vum friss�t�se">
          </FORM>
    </TD>


      </TR>

      <TR>
        <TD>
	  <FONT COLOR="--DARK_COLOR--">
	  <A HREF="[path_cgi]/scenario_test">
	     <b>V�ltozatok kipr�b�l�sa</b>
          </A>
          </FONT>
	</TD>
      </TR>
	
    </TABLE>


