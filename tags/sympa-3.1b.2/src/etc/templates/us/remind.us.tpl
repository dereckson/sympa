From: [conf->email]@[conf->host]
[IF  list->lang=fr]
Subject: Rappel de votre abonnement [list->name]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

 Vous �tes abonn� dans la liste  [list->name]@[list->host] avec l'adresse
[user->email] ;
votre mot de passe: [user->password]. 

Pour tout savoir sur cette liste : [conf->wwsympa_url]/info/[list->name]
Pour un d�sabonnement :
mailto:[conf->email]@[conf->host]?subject=sig%20[list->name]%20[user->email]

[ELSIF list->lang=es]
Subject: Recordatorio de su subscripci�n a [list->name]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

Usted es subscriptor de la lista [list->name]@[list->host] con el e-mail [user->email]
y su contrase�a es : [user->password].

Informaci�n acerca de esta lista : [conf->wwsympa_url]/info/[list->name]
Para anular su subscripci�n :
mailto:[conf->email]@[conf->host]?subject=sig%20[list->name]%20[user->email]

[ELSIF list->lang=it]
Subject: Promemoria della sua iscrizione alla lista [list->name]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

 Lei e' iscritto alla lista [list->name]@[list->host] con l'indirizzo
[user->email] ;
la sua password e' [user->password].

Per cancellare l'iscrizione :
mailto:[conf->email]@[conf->host]?subject=sig%20[list->name]%20[user->email]

[ELSE]
Subject: Reminder of your subscribtion to [list->name]

Your are subscriber of list [list->name]@[list->host] with  email [user->email] 
your password : [user->password]. 

Everything about this list : [conf->wwsympa_url]/info/[list->name]
Unsubscribtion :
mailto:[conf->email]@[conf->host]?subject=sig%20[list->name]%20[user->email]
[ENDIF]

