Inform�ci�k a(z) [list->name]@[list->host] list�r�l:

T�rgy                 : [subject]
[FOREACH o IN owner]
Tulajdonos            : [o->gecos] <[o->email]>
[END]
[FOREACH e IN editor]
Moder�tor             : [e->gecos] <[e->email]>
[END]
Feliratkoz�s          : [subscribe]
Leiratkoz�s           : [unsubscribe]
Levelek k�ld�se       : [send]
Tagok list�ja         : [review]
V�lasz c�m            : [reply_to]
Maxim�lis m�ret       : [max_size]
[IF digest]
Digest                : [digest]
[ENDIF]
Fogad�si m�d          : [available_reception_mode]
Lista web c�me	      : [url]

[PARSE 'info']
