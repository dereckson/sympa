<H1>Edition of the file [path]</H1>
    ������: [doc_owner] <BR>
    ������: [doc_date] <BR>
    ����: [desc] <BR><BR>
<H3><A HREF="[path_cgi]/d_read/[list]/[father]"> <IMG ALIGN="bottom"  src="[father_icon]"> ת����һ��Ŀ¼</A></H3>

<TABLE CELLSPACING=15>

  <TR>
  <form method="post" ACTION="[path_cgi]" ENCTYPE="multipart/form-data">
  <TD ALIGN="right" VALIGN="bottom">
  <B> �������ļ�ȡ���ļ� [path] </B><BR> 
  <input type="file" name="uploaded_file">
  </TD>
  <TD ALIGN="left" VALIGN="bottom"> 
  <input type="submit" value="����" name="action_d_overwrite">
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
  <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
  <INPUT TYPE="hidden" NAME="serial" VALUE="[serial_file]">
  </TD>
  </form>
  </TR>

  <TR>
  <FORM ACTION="[path_cgi]" METHOD="POST">
  <TD ALIGN="right" VALIGN="bottom">
  <B> ���ļ� [path] �������� </B></BR>
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
  <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
  <INPUT TYPE="hidden" NAME="serial" VALUE="[serial_desc]">
  <INPUT TYPE="hidden" NAME="action" VALUE="d_describe">
  <INPUT SIZE=50 MAXLENGTH=100 NAME="content" VALUE="[desc]">
  </TD>
  <TD ALIGN="left" VALIGN="bottom">
  <INPUT SIZE=50 MAXLENGTH=100 TYPE="submit" NAME="action_d_describe" VALUE="Ӧ��">
  </TD>
  </FORM>
  </TR>

</TABLE>
<BR>
<BR>

[IF textfile]
  <FORM ACTION="[path_cgi]" METHOD="POST">
  <B> �༭�ļ� [path]</B><BR>
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
  <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
  <INPUT TYPE="hidden" NAME="serial" VALUE="[serial_file]">
  <TEXTAREA NAME="content" COLS=80 ROWS=25>
[INCLUDE filepath]
  </TEXTAREA><BR>
  <INPUT TYPE="submit" NAME="action_d_savefile" VALUE="����">
  </FORM>
[ENDIF]





