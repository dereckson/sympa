<!-- RCS Identication ; $Revision$ ; $Date$ -->

    <TABLE WIDTH="100%" CELLPADDING="1" CELLSPACING="0">
      <TR VALIGN="top">
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH BGCOLOR="[selected_color]" WIDTH="50%">
              <FONT COLOR="[bg_color]">
	        ���Ļ���
              </FONT>
             </TH>
            </TR>
           </TABLE>
         </TH>
      </TR>
      <TR VALIGN="top">
        <TD>
          <FORM ACTION="[path_cgi]" METHOD=POST>
         
  	    <FONT COLOR="[dark_color]">�ʼ���ַ</FONT> [user->email]<BR><BR>
	    <FONT COLOR="[dark_color]">����</FONT> 
	    <INPUT TYPE="text" NAME="gecos" SIZE=20 VALUE="[user->gecos]"><BR><BR> 
	    <FONT COLOR="[dark_color]">���� </FONT>
            <SELECT NAME="lang">
              [FOREACH l IN languages]
                <OPTION VALUE='[l->NAME]' [l->selected]>[l->complete]
              [END]
            </SELECT>
            <BR><BR>
	    <FONT COLOR="[dark_color]">���ӹ���ʱ�� </FONT>
            <SELECT NAME="cookie_delay">
              [FOREACH period IN cookie_periods]
                <OPTION VALUE="[period->value]" [period->selected]>[period->desc]
              [END]
            </SELECT>
            <BR><BR>
	    <INPUT TYPE="submit" NAME="action_setpref" VALUE="�ύ"></FONT>
          </FORM>
        </TD>
      </TR>

      [IF auth=classic]
      <TR VALIGN="top">
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH WIDTH="50%" BGCOLOR="[selected_color]">
              <FONT COLOR="[bg_color]">
	        �޸������ʼ���ַ
              </FONT>
             </TH><TH WIDTH="50%" BGCOLOR="[selected_color]">
              <FONT COLOR="[bg_color]">
	        �޸����Ŀ���
              </FONT>
             </TH>
            </TR>
           </TABLE>
         </TH>

      </TR>
       
      <TR VALIGN="top">
           <TD>
           <FORM ACTION="[path_cgi]" METHOD=POST>
        
	    <BR><BR><FONT COLOR="[dark_color]">�µ��ʼ���ַ : </FONT>
            <BR>&nbsp;&nbsp;&nbsp;<INPUT NAME="email" SIZE=15>
            <BR><BR><INPUT TYPE="submit" NAME="action_change_email" VALUE="�ύ">
            </FORM>
        </TD>
        <TD>
          <FORM ACTION="[path_cgi]" METHOD=POST>
	    <BR><BR><FONT COLOR="[dark_color]">�¿���: </FONT>
            <BR>&nbsp;&nbsp;&nbsp;<INPUT TYPE="password" NAME="newpasswd1" SIZE=15>
	    <BR><FONT COLOR="[dark_color]">���������¿���: </FONT>
            <BR>&nbsp;&nbsp;&nbsp;<INPUT TYPE="password" NAME="newpasswd2" SIZE=15>
            <BR><BR><INPUT TYPE="submit" NAME="action_setpasswd" VALUE="�ύ">
            </FORM>
	    [ENDIF]

        </TD>
	<TR VALIGN="top">
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH WIDTH="50%" BGCOLOR="[selected_color]">
              <FONT COLOR="[bg_color]">
                ���������ʼ�λַ
              </FONT>
             </TH>
            </TR>
           </TABLE>
         </TH>
      </TR>
      [IF !unique]
      <TR VALIGN="top">
      <TD>  
            <FORM ACTION="[path_cgi]" METHOD=POST> 
   	    [FOREACH email IN alt_emails]
	    <A HREF="[path_cgi]/change_identity/[email->NAME]/pref">[email->NAME]</A>
	    <INPUT NAME="email" TYPE=hidden VALUE="[email->NAME]">
	    <BR>
	    [END]
	    </FORM>
      </TD>
      </TR> 
      [ENDIF]
      <TR VALIGN="top">
      <TD>
	    <FORM ACTION="[path_cgi]" METHOD=POST> 
	    <BR>
	    <FONT COLOR="[dark_color]">�����λַ: </FONT>
	    &nbsp;&nbsp;&nbsp;<INPUT NAME="new_alternative_email" SIZE=15>
	    &nbsp;&nbsp;&nbsp;<FONT COLOR="[dark_color]">����: </FONT>
	    &nbsp;&nbsp;&nbsp;<INPUT TYPE = "password" NAME="new_password" SIZE=8>
            &nbsp;&nbsp;&nbsp &nbsp; <INPUT TYPE="submit" NAME="action_record_email" VALUE="�ύ">
            </FORM>
      </TD>
      <TD VALIGN="middle">
      Sympa ��֪���������ĵ�ַ.  
      </TD>
      </TR>
      </TABLE>
