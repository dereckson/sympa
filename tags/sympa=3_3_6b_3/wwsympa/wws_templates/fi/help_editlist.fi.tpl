<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH p IN param]
<A NAME="[p->NAME]">
<B>[p->title]</B> ([p->NAME]):
<DL>
<DD>
[IF p->NAME=add]
  Oikeudet lis�t� tilaajia (ADD komento) listalle
[ELSIF p->NAME=anonymous_sender]
  L�hett�j�n email osoitteen piilottaminen ennen l�hett�mist�.
  Se korvataan annetulla email osoitteella.
[ELSIF p->NAME=archive]
  Oikeudet arkistojen lukuun ja arkistoinnin aikav�li
[ELSIF p->NAME=owner]
 Omistajat hallitsevat listan tilaajia. He voivat tarkistaa, lis�t� tai poistaa
 osoitteita listalta. Jos ole listan oikeutettu omistaja, voit valita listan 
 muut omistajat. Oikeutetut omistajat voivat muuttaa enemm�n asetuksia kuin muut.
 Listalla voi olla vain yksi oikeutettu omistaja; h�nen osoitettaan ei voi muuttaa
 WWW-liittym�n kautta.	
[ELSIF p->NAME=editor]
  Tarkistajat ovat vastuussa viestien hallinnoinnista. Jos lista on hallittu,
  viestien menev�t ensin tarkistajille jotka p��tt�v�t l�hetet��nk� vai hyl�t��nk�
  viesti.<BR>
  HUOM: Tarkistajien m��ritt�minen ei tee listasta hallittua ; sinun t�ytyy muuttaa
  "send" parametria.<BR>
  HUOM: Jos lista on hallittu, kuka tahansa tarkistajista voi l�hett�� tai hyl�t� 
  viestin muiden tarkistajien hyv�ksynn�st� huolimatta. Viestit joita ei ole 
  tarkistettu, j��v�t jonoon kunnes ne on hyv�ksytty tai hyl�tty.
[ELSE]
  Ei kommenttia
[ENDIF]

</DL>
[END]
	
