From: [conf->email]@[conf->host]
To: [to]
Subject: Lista tuntematon
Mime-version: 1.0
Content-Type: multipart/report; report-type=delivery-status; 
	boundary="[boundary]"

--[boundary]
Content-Description: Notification
Content-Type: text/plain

T�m� on automaattinen vastaus jonka l�hetti Sympa Postituslista ohjelmisto.

Seuraava osoite ei ole tunnettu lista :

	[list]

L�yt��ksesi oikean listan nimen, kysy sit� palvelimen listahakemistosta :

	mailto:[conf->email]@[conf->host]?subject=WHICH

Lis�tietoja saat ottamalla yhteytt� listmaster@[conf->host]

--[boundary]
Content-Type: message/delivery-status

Reporting-MTA: dns; [conf->host]
Arrival-Date: [date]

Final-Recipient: rfc822; [list]
Action: failed
Status: 5.1.1
Remote-MTA: dns; [conf->host]
Diagnostic-Code: List unknown

--[boundary]
Content-Type: text/rfc822-headers

[header]

--[boundary]--
