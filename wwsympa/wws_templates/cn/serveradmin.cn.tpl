<!-- RCS Identication ; $Revision$ ; $Date$ -->

    <TABLE WIDTH="100%" BORDER=0 CELLPADDING=10>
      <TR VALIGN="top">
        <TD NOWRAP>
	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <FONT COLOR="--DARK_COLOR--"><B>����Ĭ���ʵݱ�ģ��</B></FONT><BR>
	     <SELECT NAME="file">
	      [FOREACH f IN lists_default_files]
	        <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="�༭">
	  </FORM>

	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <FONT COLOR="--DARK_COLOR--"><B>����վ��ģ��</B></FONT><BR>
	     <SELECT NAME="file">
	      [FOREACH f IN server_files]
	        <OPTION VALUE='[f->NAME]' [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="�༭">
	  </FORM>
	</TD>
      </TR>
      <TR><TD><A HREF="[path_cgi]/get_pending_lists"><B>�������ʵݱ�</B></A></TD></TR>
      <TR><TD><A HREF="[path_cgi]/view_translations"><B>����ģ��</B></A></TD></TR>
      <TR>
        <TD>
<FONT COLOR="--DARK_COLOR--">ʹ��<CODE>arctxt</CODE>Ŀ¼��Ϊ����<B>�ؽ� HTML �鵵</B>��
        </TD>
      </TR>
      <TR>
        <TD>
          <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="submit" NAME="action_rebuildallarc" VALUE="ȫ��"><BR>
	����Ҫռ�úܴ�� CPU ʱ�䣬С��ʹ��!
          </FORM>
	</TD>

    <TD ALIGN="CENTER"> 
          <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="text" NAME="list" SIZE="20">
          <INPUT TYPE="submit" NAME="action_rebuildarc" VALUE="�ؽ��鵵">
          </FORM>
    </TD>


      </TR>

      <TR>
        <TD>
	  <FONT COLOR="--DARK_COLOR--">
	  <A HREF="[path_cgi]/scenario_test">
	     <b>�龰����ģ��</b>
          </A>
          </FONT>
	</TD>
      </TR>
	
    </TABLE>


