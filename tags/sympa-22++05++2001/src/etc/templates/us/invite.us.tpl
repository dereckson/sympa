From: [requested_by]
Reply-To: [conf->sympa]
Subject: [subject]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit


[IF list->lang=fr]

Bonjour,

Je vous invite � vous abonner � la liste  [list->name]@[list->host], cette
liste traite de [list->subject], vous �tes donc surement concern�.

Pour vous abonner r�pondez simplement � ce message ou cliquez l'url
mailto suivante : [url]

Si vous ne voulez pas vous abonner ignorez ce message.

[ELSIF list->lang=es]

Hola,

Le invito a subscribirse a la lista de correo [list->name]@[list->host]. 
Esta lista trata de [list->subject], con lo que puede ser de su inter�s.

Para subscribirse simplemente responda a este mensaje o haga un click en el
siguiente enlace de correo :  [url]

Si no desea subscribirse, simplemente ignore este mensaje.

[ELSIF list->lang=it]

Buongiorno,

La invito a iscriversi alla lista  [list->name]@[list->host], questa
lista tratta di [list->subject], lei e' quindi sicuramente interessato.

Per iscriversi risponda a questo messaggio o clicchi l'URL :
[url]

Se non vuole iscriversi, ignori questo messaggio.
[ELSIF list->lang=pl]
Witaj,

Zapraszam Ci� do zapisania na list� [list->name]@[list->host].
Tematem listy jest [list->subject], wi�c mo�e Ci� to zainteresowa�.

�eby si� zapisa� odpowiedz na ten list klikaj�c na url :
[url]

Je�eli nie chesz si� zapisa�, nie odpowiadaj na ten list.

[ELSIF list->lang=cz]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

Dobr� den,

Zvu V�s k p�ihl�en� do konference [list->name]@[list->host].
T�matem konference je [list->subject], co� V�s m��e zaj�mat.

Chcete-li se p�ihl�sit, odpov�zte na tuto zpravu, nebo
otev�ete n�sleduj�c� odkaz:
[url]

Nem�te-li z�jem, ignorujte pros�m tuto zpravu.

[ELSIF list->lang=de]

Guten Tag,

Diese Mailing-Liste handelt von [list->subject]. Falls Sie intressiert
sind, antworten Sie einfach auf diese EMail oder benutzen Sie die
folgende URL:
[url]

Falls nicht, ignorieren Sie diese Nachricht am besten.

[ELSIF list->lang=hu]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

�dv!

Szeretn�nk, ha  a(z) [list->name]@[list->host] lista tagja lenn�l.
A lista t�mak�re: [list->subject]

Ha fel szeretn�l iratkozni, akkor v�laszolj erre a lev�lre vagy
erre a c�mre:
[url]

Ha nem �rdekel a lista, akkor nyugodtan t�r�ld ezt a levelet.

[ELSE]
Hi,

This list is about [list->subject], so you are probably concern.

To subscribe just reply to this message or hit the following mailto url :
[url]

If you don't want to subscribe just ignore this message.

[ENDIF]


