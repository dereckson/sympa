<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF status=open]
A lista m�k�dik.<BR> 
A <B>lista adminisztr�ci�</B> gombra kattintva a lista tulajdons�gait, param�tereit �ll�thatod be.
<BR>
[IF auto_aliases]
A lista bejegyz�sek (aliases) elmentve.
[ELSE]
 <TABLE BORDER=1>
 <TR BGCOLOR="[light_color]"><TD align=center>Sz�ks�ges bejegyz�sek</TD></TR>
 <TR>
 <TD>
 <pre><code>
 [aliases]
 </code></pre>
 </TD>
 </TR>
 </TABLE>
[ENDIF]

[ELSE]
Lista l�trehoz�si ig�nyedet bejegyezt�k. A lista be�ll�t�sait 
az admin gombra kattintva v�gezheted el, azonban a lista csak
a listmaster j�v�hagy�sa ut�n fog m�k�dni.
[ENDIF]
