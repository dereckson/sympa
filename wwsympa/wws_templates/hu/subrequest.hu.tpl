<!-- RCS Identication ; $Revision$ ; $Date$ -->

  [IF status=auth]

	[list] list�ra szeretn�l feliratkozni. <BR>Feliratkoz�si k�relmed
	meger�s�t�s�hez kattints a lenti gombra: <BR>
	<BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_subscribe" VALUE="[list] list�ra feliratkozom">
	</FORM>

  [ELSIF status=notauth_passwordsent]

    	[list] list�ra szeretn�l feliratkozni. 
	<BR><BR>
	Azonos�t�sodhoz �s hogy m�sok vissza ne tudjanak �lni a tags�goddal
	emailben elk�ld�sre ker�l a jelszavad.<BR><BR>

	A lev�lben tal�lhat� jelsz�t kell megadnod lentebb a(z) [list]
	list�ra t�rt�n� feliratkoz�sod meger�s�t�s�hez.
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>email c�m</B> </FONT>[email]<BR>
	  <FONT COLOR="[dark_color]"><B>jelsz�</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_subscribe" VALUE="Feliratkoz�s">
        </FORM>

      	A jelszavaddal �s email c�meddel az egy�ni be�ll�t�saidat
	tudod k�s�bb megv�ltoztatni.

  [ELSIF status=notauth_noemail]

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>Email c�med</B> 
	  <INPUT  NAME="email" SIZE="30"><BR>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="action" VALUE="subrequest">
	  <INPUT TYPE="submit" NAME="action_subrequest" VALUE="Elk�ld">
         </FORM>


  [ELSIF status=notauth]

	Feliratkoz�sod meger�s�t�s�hez a(z) [list] list�ra k�rlek
	add meg a jelszavadat:

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>Email c�m</B> </FONT>[email]<BR>
            <FONT COLOR="[dark_color]"><B>Jelsz�</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_subscribe" VALUE="Feliratkoz�s">
	<INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Jelszavam?">
         </FORM>

  [ELSIF status=notauth_subscriber]

	<FONT COLOR="[dark_color]"><B>M�r tagja vagy a(z) [list] list�nak.
	</FONT>
	<BR><BR>


	[PARSE '--ETCBINDIR--/wws_templates/loginbanner.hu.tpl']

  [ENDIF]      



