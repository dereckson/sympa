Informations sur la liste [list->name]@[list->host] :

Sujet              : [subject]
[FOREACH o IN owner]
Propri�taire       : [o->gecos] <[o->email]>
[END]
[FOREACH e IN editor]
Mod�rateur         : [e->gecos] <[e->email]>
[END]
Abonnement         : [subscribe]
D�sabonnement      : [unsubscribe]
Envoi de messages  : [send]
Liste des abonn�s  : [review]
R�ponse �          : [reply_to]
Taille maximale    : [max_size]
[IF digest]
Digest             : [digest]
[ENDIF]
Modes de r�ception : [available_reception_mode]
Page web           : [url]

[PARSE 'info']
