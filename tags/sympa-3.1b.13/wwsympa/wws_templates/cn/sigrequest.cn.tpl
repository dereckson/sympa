<!-- RCS Identication ; $Revision$ ; $Date$ -->

  [IF status=auth]
      �������˶��ʵݱ� [list]��<BR>Ҫȷ�����������������İ�ť:<BR>
	<BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_signoff" VALUE="���˶��ʵݱ� [list]">
	</FORM>

  [ELSIF not_subscriber]

      ��û�����ʼ���ַ [email] �����ʵݱ� [list]��
      <BR><BR>
      ������ʹ���������ʼ���ַ���ĵ��ʵݱ�
      ����ϵ�ʵݱ����������������˶�:
      <A HREF="mailto:[list]-request@[conf->host]">[list]-request@[conf->host]</A>
      
  [ELSIF init_passwd]
        �������˶��ʵݱ� [list]��
	<BR><BR>
	Ϊ��ȷ��������ݣ�����������Υ��������Ը����������ʵݱ����˶���������
	һ������ URL ���ʼ�������<BR><BR>

	��������ʼ��䣬Ȼ������������ Sympa ���͸������ʼ��еĿ���⽫
	ȷ�����˶��ʵݱ� [list]��
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="--DARK_COLOR--"><B>e-mail address</B> </FONT>[email]<BR>
            <FONT COLOR="--DARK_COLOR--"><B>����</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="�˶�">
        </FORM>

      	�������������ʼ���ַ�����������������Լ��Ķ��ƻ�����

  [ELSIF ! email]
      ������˶��ʵݱ� [list] ���õ��ʼ���ַ��

      <FORM ACTION="[path_cgi]" METHOD=POST>
          <B>�����ʼ���ַ: </B> 
          <INPUT NAME="email"><BR>
          <INPUT TYPE="hidden" NAME="action" VALUE="sigrequest">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
         </FORM>


  [ELSE]

	Ϊ��ȷ�����˶��ʵݱ� [list]�����������������Ŀ���:

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="--DARK_COLOR--"><B>e-mail address</B> </FONT>[email]<BR>
            <FONT COLOR="--DARK_COLOR--"><B>����</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="�˶�">

<BR><BR>
<I>���������û�дӷ�������ù���������������˿���: </I>  <INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="���ҷ��Ϳ���">

         </FORM>

  [ENDIF]      













