<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF url]
<H1>[path] k�nyvjelz� (bookmark) szerkeszt�se</H1>
[ELSIF directory]
<H1>[path] k�nyvt�r szerkeszt�se</H1>
[ELSE]
<H1>[path] �llom�ny szerkeszt�se</H1>
[ENDIF]
    Tulajdonos: [doc_owner] <BR>
    Utols� m�dos�t�s: [doc_date] <BR>
    Le�r�s: [desc] <BR><BR>
<H3><A HREF="[path_cgi]/d_read/[list]/[escaped_father]"> <IMG ALIGN="bottom"  src="[father_icon]">Egy k�nyvt�rral feljebb</A></H3>

<TABLE CELLSPACING=15>

[IF !directory]
  <TR>
  <form method="post" ACTION="[path_cgi]" ENCTYPE="multipart/form-data">
  <TD ALIGN="right" VALIGN="bottom">
[IF url]
  <B>Webc�m felv�tele a k�nyvjelz�be</B><BR>
  <input name="url" VALUE="[url]">
[ELSE]
  <B> A(z) [path] �llom�ny fel�l�r�sa </B><BR> 
  <input type="file" name="uploaded_file">
[ENDIF]
  </TD>
  <TD ALIGN="left" VALIGN="bottom"> 
[IF url]
  <input type="submit" value="V�ltoztat" name="action_d_savefile">
[ELSE]
  <input type="submit" value="Felt�lt" name="action_d_overwrite">
[ENDIF]
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
  <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
  <INPUT TYPE="hidden" NAME="serial" VALUE="[serial_file]">
  </TD>
  </form>
  </TR>
[ENDIF]

  <TR>
  <FORM ACTION="[path_cgi]" METHOD="POST">
  <TD ALIGN="right" VALIGN="bottom">
[IF directory]
  <B>[path] k�nyvt�r tulajdons�gai</B></BR>
[ELSE]
  <B>[path] �llom�ny tulajdons�gai</B></BR>
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
  <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
  <INPUT TYPE="hidden" NAME="serial" VALUE="[serial_desc]">
  <INPUT TYPE="hidden" NAME="action" VALUE="d_describe">
  <INPUT SIZE=50 MAXLENGTH=100 NAME="content" VALUE="[desc]">
  </TD>
  <TD ALIGN="left" VALIGN="bottom">
  <INPUT SIZE=50 MAXLENGTH=100 TYPE="submit" NAME="action_d_describe" VALUE="Alkalmaz">
  </TD>
  </FORM>
  </TR>

</TABLE>
<BR>
<BR>

[IF !url]
[IF textfile]
  <FORM ACTION="[path_cgi]" METHOD="POST">
  <B> [path] �llom�ny szerkeszt�se</B><BR>
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
  <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
  <INPUT TYPE="hidden" NAME="serial" VALUE="[serial_file]">
  <TEXTAREA NAME="content" COLS=80 ROWS=25>
[INCLUDE filepath]
  </TEXTAREA><BR>
  <INPUT TYPE="submit" NAME="action_d_savefile" VALUE="Elment">
  </FORM>
[ENDIF]
[ENDIF]




