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
Subject: Cancellazione iscrizione [list->name]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

 Il suo indirizzo [user->email] e' stato cancellato dalla lista [list->name]@[list->host]
 Grazie per avere usato questa lista.
 Arrivederci !

[ELSIF list->lang=pl]
Subject: Wypisanie z listy [list->name]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

 Tw�j adres email [user->email] zosta� wypisany z listy [list->name]@[list->host]
 Do widzenia!

[ELSIF list->lang=cz]
Subject: Odhlaseni z konference [list->name]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

 Va�e emailov� adresa [user->email] byla odstran�na ze seznamu 
 konference [list->name]@[list->host].
 Na shledanou!

[ELSIF list->lang=de]
Subject: Abmeldung von der Mailing-Liste [list->name]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

 Ihr Abonnement f�r die Mailing-Liste [list->name]@[list->host] unter der
 Adresse [user->email] wurde beendet.
 Auf Wiedersehen!

[ELSIF list->lang=hu]
Subject: [list->name] list�r�l leiratkoz�s
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

 Email c�med ([user->email]) t�r�lve lett a(z) [list->name]@[list->host]
 levelez�list�r�l!
 Viszl�t!
 
[ELSE]
Subject: Unsubscription from [list->name]

 Your email address ([user->email]) has been removed from list [list->name]@[list->host]
 bye !

[ENDIF]

