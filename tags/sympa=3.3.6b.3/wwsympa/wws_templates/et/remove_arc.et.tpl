<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF status = done]
<b>Tegevus �nnestus</b>. Kiri kustutatakse niipea, kui v�imalik. See
v�ib v�tta m�ned minutid, uuendage muudetud lehte oma brauseris. 
[ELSIF status = no_msgid]
<b>Ei saa kustutada kirja, t�en�oliselt selle t�ttu, et kirjal ei olnud
p�ises "Message-Id:" rida. Palun saatke listmasterile kirja t�ielik 
URL.
</b>
[ELSIF status = not_found]
<b>Ei leia kirja, mida kustutada soovite</b>
[ELSE]
<b>Viga kirja kustutamisel, palun saatke listmasterile kirja arhiivi 
t�ielik URL.
</b>
[ENDIF]
