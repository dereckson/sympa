<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF status=open]
A lista m�k�dik.<BR> 
Az <B>admin</B> gombra kattintva �ll�thatod be a param�tereit.
<BR>
[IF auto_aliases]
A lista bejegyz�sek (aliases) mentve lettek.
[ELSE]
 <TABLE BORDER=1>
 <TR BGCOLOR="--LIGHT_COLOR--"><TD align=center>Sz�ks�ges bejegyz�sek</TD></TR>
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
