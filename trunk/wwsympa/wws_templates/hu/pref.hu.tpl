<!-- RCS Identication ; $Revision$ ; $Date$ -->


    <TABLE WIDTH="100%" CELLPADDING="1" CELLSPACING="0">
      <TR VALIGN="top">
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH BGCOLOR="[selected_color]" WIDTH="50%">
	      <FONT COLOR="[bg_color]">
	        Be�ll�t�saim
	      </FONT>
	     </TH>
            </TR>
           </TABLE>
         </TH>
      </TR>
      <TR VALIGN="top">
	<TD>
	  <FORM ACTION="[path_cgi]" METHOD=POST>
  	    <FONT COLOR="[dark_color]">E-mail: </FONT> [user->email]<BR><BR>
	    <FONT COLOR="[dark_color]">N�v: </FONT> 
	    <INPUT TYPE="text" NAME="gecos" SIZE=20 VALUE="[user->gecos]"><BR><BR> 
	    <FONT COLOR="[dark_color]">Nyelv: </FONT>
	    <SELECT NAME="lang">
	      [FOREACH l IN languages]
	        <OPTION VALUE='[l->NAME]' [l->selected]>[l->complete]
	      [END]
	    </SELECT>
	    <BR><BR>
	    <FONT COLOR="[dark_color]">Kapcsolat lej�r </FONT>
	    <SELECT NAME="cookie_delay">
	      [FOREACH period IN cookie_periods]
	        <OPTION VALUE="[period->value]" [period->selected]>[period->desc]
	      [END]  
	    </SELECT>
	    <BR><BR>
	    <INPUT TYPE="submit" NAME="action_setpref" VALUE="Ment�s"></FONT>
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
	        E-mail c�m megv�ltoztat�sa
	      </FONT>
	     </TH><TH WIDTH="50%" BGCOLOR="[selected_color]">
	      <FONT COLOR="[bg_color]">
	        Jelsz� megv�ltoztat�sa
	      </FONT>
	     </TH>
            </TR>
           </TABLE>
         </TH>
      </TR>
      <TR VALIGN="top">
        <TD>
   	    <FORM ACTION="[path_cgi]" METHOD=POST>
	    <BR><BR><BR><FONT COLOR="[dark_color]">�j c�m: </FONT>
	    <BR>&nbsp;&nbsp;&nbsp;<INPUT NAME="email" SIZE=15>
	    <BR><BR><BR><INPUT TYPE="submit" NAME="action_change_email" VALUE="Ment�s">
	    </FORM>
	</TD>
	<TD>
	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <BR><BR><BR><FONT COLOR="[dark_color]">�j jelsz�: </FONT>
	    <BR>&nbsp;&nbsp;&nbsp;<INPUT TYPE="password" NAME="newpasswd1" SIZE=15>
	    <BR><FONT COLOR="[dark_color]">�j jelsz� m�g egyszer: </FONT>
	    <BR>&nbsp;&nbsp;&nbsp;<INPUT TYPE="password" NAME="newpasswd2" SIZE=15>
	    <BR><BR><INPUT TYPE="submit" NAME="action_setpasswd" VALUE="Ment�s">
	    </FORM>
        [ENDIF]

        </TD>
	<TR VALIGN="top">
	<TH BGCOLOR="[dark_color]" COLSPAN="2">
	 <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
	 <TR>
	 <TH WIDTH="50%" BGCOLOR="[selected_color]"> 
	 <FONT COLOR="[bg_color]">
	 Tov�bbi e-mail c�meim
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
	   <FONT COLOR="[dark_color]">M�sik e-mail c�m: </FONT>
	   &nbsp;&nbsp;&nbsp;<INPUT NAME="new_alternative_email" SIZE=15>
	   &nbsp;&nbsp;&nbsp;<FONT COLOR="[dark_color]">Jelsz�: </FONT>
	   &nbsp;&nbsp;&nbsp;<INPUT TYPE = "password" NAME="new_password" SIZE=8>
	   &nbsp;&nbsp;&nbsp &nbsp; <INPUT TYPE="submit" NAME="action_record_email" VALUE="Elk�ld">
	 </FORM> 
	 </TD>
	 <TD VALIGN="middle">
	 Azt a m�sik e-mail c�met adjuk meg, amelyet m�g haszn�lni szeretn�nk a Sympan�l.
       
	</TD>
      </TR>


    </TABLE>
