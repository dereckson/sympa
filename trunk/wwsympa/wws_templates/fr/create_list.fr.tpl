<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF status=open]

Votre liste est cr��e.<BR> 
Vous pouvez la configurer via le bouton <b>Admin liste</b> ci-contre.
<BR>
[IF auto_aliases]
Les alias ont �t� install�s.
[ELSE]
 <TABLE BORDER=1>
 <TR BGCOLOR="[light_color]"><TD align=center>Les alias � installer </TD></TR>
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

Votre demande de cr�ation de liste est enregistr�e. Vous pouvez 
la modifier en utilisant le bouton <b>Admin liste</b>. Mais cette liste
ne sera effectivement install�e et rendue visible sur ce serveur
que quand le listmaster validera sa cr�ation.
[ENDIF]
