<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF status = done]
<b>M�velet sikeresen befejezve.</b> Az �zenetet amint lehet t�r�lni
fogjuk. Ez p�r percen bel�l megt�rt�nhet, fontos hogy ne felejtsd el
friss�teni a hivatkoz� oldalt.
[ELSIF status = no_msgid]
<b>A t�rl�sre sz�nt �zenet nem tal�lhat�, val�sz�n�leg az �zenetet
"Message-Id:" azonos�t� n�lk�l kaptad. K�rlek fordulj a listmasterhez
a t�rl�sre sz�nt �zenet teljes c�m�vel (URL).
</center>
[ELSIF status = not_found]
<b>A t�rl�sre sz�nt �zenet nem tal�lhat�.</b>
[ELSE]
<b>Hiba az �zenet t�rl�s�n�l, k�rlek fordulj a listmasterhez a 
t�rl�sre sz�nt �zenet teljes c�m�vel (URL).</b>
[ENDIF]
