<!-- RCS Identication ; $Revision$ ; $Date$ -->

      �������˿������������û�л������������ϵ��ʵݱ����<BR>
      ���ͨ�������ʼ����͸���:

      <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="referer" VALUE="[referer]">
        <B>���ĵ����ʼ���ַ</B>: <BR>
        [IF email]
	  [email]
          <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	[ELSE]
	  <INPUT TYPE="text" NAME="email" SIZE="20">
	[ENDIF]
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="���ҷ��Ϳ���">
      </FORM>
