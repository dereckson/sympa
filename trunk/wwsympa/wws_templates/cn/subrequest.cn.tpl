<!-- RCS Identication ; $Revision$ ; $Date$ -->

  [IF status=auth]

	���������ʵݱ� [list]��<BR>Ҫȷ������������������İ�ť: <BR>
	<BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_subscribe" VALUE="�Ҷ����ʵݱ� [list]">
	</FORM>

  [ELSIF status=notauth_passwordsent]

    	���������ʵݱ� [list]��
	<BR><BR>
	Ϊ��ȷ��������ݣ�����������Υ��������ԸΪ����������ʵݱ�������һ������
	���Ŀ�����ʼ�������<BR><BR>

	��������ʼ��䣬Ȼ���������������⽫ȷ���������ʵݱ� [list]��
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="--DARK_COLOR--"><B>e-mail address</B> </FONT>[email]<BR>
	  <FONT COLOR="--DARK_COLOR--"><B>����</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_subscribe" VALUE="����">
        </FORM>

      	�������������ʼ���ַ�����������������Լ��Ķ��ƻ�����

  [ELSIF status=notauth_noemail]

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="--DARK_COLOR--"><B>���ĵ����ʼ���ַ</B> 
	  <INPUT  NAME="email" SIZE="30"><BR>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="action" VALUE="subrequest">
	  <INPUT TYPE="submit" NAME="action_subrequest" VALUE="�ύ">
         </FORM>


  [ELSIF status=notauth]

	Ϊ��ȷ���������ʵݱ� [list]�����������������Ŀ���:

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="--DARK_COLOR--"><B>�����ʼ���ַ</B> </FONT>[email]<BR>
            <FONT COLOR="--DARK_COLOR--"><B>����</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_subscribe" VALUE="����">
	<INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="�ҵĿ��� ?">
         </FORM>

  [ELSIF status=notauth_subscriber]

	<FONT COLOR="--DARK_COLOR--"><B>���Ѿ��������ʵݱ� [list]��
	</FONT>
	<BR><BR>


	[PARSE '--ETCBINDIR--/wws_templates/loginbanner.cn-gb.tpl']

  [ENDIF]      



