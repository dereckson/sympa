<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF status = done]
<b>Operaatio onnistui</b>. Viesti poistetaan mahdollisimman pian.
T�m� saattaa kest�� muutaman minuutin, muista p�ivitt�� sivu.
[ELSIF status = no_msgid]
<b>Viesti� ei l�ydy poistettavaksi</b>, tod. n�k. viesti
saaapui ilman "Message-Id:" Ota yhteytt� Listmasteriin
ja liit� mukaan viestin koko URL
[ELSIF status = not_found]
<b>Viesti� ei l�ydy poistettavaksi</b>
[ELSE]
<b>Virhe viesti� poistettaessa</b>, ota yhteytt� Listmasteriin
ja liit� mukaan viestin koko URL.
[ENDIF]
