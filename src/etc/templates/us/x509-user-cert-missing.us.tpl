From: [list->name]-request@[list->host]
[IF  list->lang=fr]
Subject: Message confidentiel de la liste [list->name]@[list->host]
Mime-version: 1.0
Content-Type: text/plain
Content-transfer-encoding: 8bit

Un message crypt� �mis par [mail->sender] a �t� diffus� dans la liste.
Objet du message : [mail->subject]

Il n'a pas �t� possible de vous remettre ce message car le serveur
de liste ne dispose pas de votre certificat X509 (pour l'adresse
[user->email]). Pour rem�dier � l'avenir � ce probl�me, envoyez un
message sign� � l'adresse
[conf->email]@[conf->host] .

Pour toutes informations sur cette liste  :
[conf->wwsympa_url]/info/[list->name]

[ELSE]
Subject: crypted message for list [list->name]@[list->host]
Mime-version: 1.0
Content-Type: text/plain
Content-transfer-encoding: 8bit

Un encrypted message from [mail->sender] has been distributed to
[list->name]@[list->host] list subscribers.
Subject : [mail->subject]

It was not possible to send it to you because the mailing list manager
was unable to access to your personal certificat (email [user->email]).
Please, in order to receive futur crypted messages send a signed message
to  [conf->email]@[conf->host] .

Any information about this list :
[conf->wwsympa_url]/info/[list->name]
[ENDIF]

