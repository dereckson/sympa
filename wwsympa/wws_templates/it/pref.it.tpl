
    <TABLE WIDTH="100%" CELLPADDING="1" CELLSPACING="0">
      <TR VALIGN="top">
        <TH BGCOLOR="#330099" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH BGCOLOR="#3366cc" WIDTH="50%">
	      <FONT COLOR="#ffffff">
	        Le tue preferenze
	      </FONT>
	     </TH><TH WIDTH="50%" BGCOLOR="#3366cc">
	      <FONT COLOR="#ffffff">
	        Cambia la tua password
	      </FONT>
	     </TH>
            </TR>
           </TABLE>
         </TH>
      </TR>
      <TR VALIGN="top">
	<TD>
	  <FORM ACTION="[path_cgi]" METHOD=POST>
  	    <FONT COLOR="#330099">Email </FONT> [user->email]<BR><BR>
	    <FONT COLOR="#330099">Nome</FONT> 
	    <INPUT TYPE="text" NAME="gecos" SIZE=20 VALUE="[user->gecos]"><BR><BR> 
	    <FONT COLOR="#330099">Lingua </FONT>
	    <SELECT NAME="lang">
	      [FOREACH l IN languages]
	        <OPTION VALUE='[l->NAME]' [l->selected]>[l->complete]
	      [END]
	    </SELECT>
	    <BR><BR>
	    <FONT COLOR="#330099">Durata della connessione (cookie) </FONT>
	    <INPUT TYPE="text" NAME="cookie_delay" SIZE=3 VALUE="[user->cookie_delay]"> min<BR><BR>
	    <INPUT TYPE="submit" NAME="action_setpref" VALUE="Setta"></FONT>
	  </FORM>
	</TD>
	<TD>
	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <BR><BR><BR><FONT COLOR="#330099">Nuova password : </FONT>
	    <BR>&nbsp;&nbsp;&nbsp;<INPUT TYPE="password" NAME="newpasswd1" SIZE=15>
	    <BR><FONT COLOR="#330099">Conferma la nuova password : </FONT>
	    <BR>&nbsp;&nbsp;&nbsp;<INPUT TYPE="password" NAME="newpasswd2" SIZE=15>
	    <BR><BR><BR><INPUT TYPE="submit" NAME="action_setpasswd" VALUE="Cambia">
	    </FORM>
	</TD>
      </TR>
    </TABLE>
