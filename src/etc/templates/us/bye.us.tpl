From: [conf->email]@[conf->host]
[IF  list->lang=fr]
Subject: Desabonnement [list->name]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

 Vous ([user->email]) �tes d�sabonn� de la liste  [list->name]@[list->host] 
 Au revoir !

[ELSIF list->lang=es]
Subject: Anulaci�n subscripci�n a [list->name]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

 Su direcci�n ([user->email]) ha sido suprimida de la lista [list->name]@[list->host] 
 Gracias por su colaboraci�n y hasta pronto !

[ELSIF list->lang=it]
From: [conf->email]@[conf->host]
Subject: Cancellazione iscrizione [list->name]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

 Il suo indirizzo [user->email] e' stato cancellato dalla lista [list->name]@[list->host]
 Grazie per avere usato questa lista.
 Arrivederci !

[ELSE]
Subject: Unsubscription from [list->name]

 Your email address ([user->email]) has been removed from list [list->name]@[list->host]
 bye !

[ENDIF]

