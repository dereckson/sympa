<!-- RCS Identication ; $Revision$ ; $Date$ -->

  [IF status=auth]
      Pyysit poistoa listalta [list]. <BR>Varmistaaksesi
      pyynt�si, paina alla olevaa nappia : <BR>
	<BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_signoff" VALUE="Poistun listalta [list]">
	</FORM>

  [ELSIF not_subscriber]

      Et ole tilaajana listaan [list] osoitteella
      [email].
      <BR><BR>
      Saatat olla tilaajana eri osoitteella.
      Ota yhteytt� listan omistajaan niin 
      saat apua listalta poistumiseen :
      <A HREF="mailto:[list]-request@[conf->host]">[list]-request@[conf->host]</A>
      
  [ELSIF init_passwd]
        Pyysit poistoa listalta [list]. 
	<BR><BR>
	Varmistaaksesi henkil�llisyytesi ja est��ksemme muita poistamasta sinua,
	viesti joka sis�lt�� URL osoitteen l�hetet��n sinulle.
        <BR><BR>
	Tarkista postisi ja anna salasanasi jonka Sympa l�hetti.
        T�ll� varmistetaan poistumisesi listalta [list].
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>e-mail osoite</B> </FONT>[email]<BR>
            <FONT COLOR="[dark_color]"><B>salasana</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="Poistu listalta">
        </FORM>

	T�m� salasana email osoitteeseen liitettyn�, sallii p��syn WWW-liittym��n.

  [ELSIF ! email]
      	
	Anna email osoitteesi listalta [list] poistumispyynt�� varten.

      <FORM ACTION="[path_cgi]" METHOD=POST>
          <B>Email osoite :</B> 
          <INPUT NAME="email"><BR>
          <INPUT TYPE="hidden" NAME="action" VALUE="sigrequest">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="submit" NAME="action_sigrequest" VALUE="Poistu listalta">
         </FORM>


  [ELSE]
	
	Varmistaaksesi listalta [list] poistuminen, anna salasana :

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>e-mail osoite</B> </FONT>[email]<BR>
            <FONT COLOR="[dark_color]"><B>salasana</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="Poistu listalta">

<BR><BR>
<I>Jos et ole koskaan saanut salasanaa tai et muista sit� :</I>  <INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="L�het� salasanani">

         </FORM>

  [ENDIF]      













