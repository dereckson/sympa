<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF status = done]
<b>Operace �sp�n� dokon�ena</b>. 
Zpr�va bude odstran�na co nejd��ve. Tento proces bude mo�n� n�kolik minut trvat,
nezapom��te na��st znovu danou str�nku.
[ELSIF status = no_msgid]
<b>Nelze naj�t zpr�vu ke smaz�n�, pravd�podobn� tato zpr�va p�i�la bez parametru
"Message-Id:". Po�lete pros�m spr�vci kompletn� odkaz na inkriminovanou zpr�vu.
</b>
[ELSIF status = not_found]
<b>Nelze naj�t zpr�vu ke smaz�n�</b>
[ELSE]
<b>Chyba p�i v�mazu zpr�vy, po�lete pros�m sprvci kompletn� odkaz na
na inkriminovanou zpr�vu.</b>
[ENDIF]

