<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF status=open]
Listasi on luotu.<BR>
Voit muuttaa asetuksia <B>hallinta</B> napin kautta.
<BR>
[IF auto_aliases]
Aliakset on asennettu.
[ELSE]
 <TABLE BORDER=1>
 <TR BGCOLOR="[light_color]"><TD align=center>Vaaditut aliakset</TD></TR>
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
Listaluonti pyynt�si on rekister�ity. Voit muuttaa sen asetuksia hallinta napin kautta,
mutta listaa ei voi k�ytt�� ennenkuin yll�pit�j� on hyv�ksynyt listan.
[ENDIF]
