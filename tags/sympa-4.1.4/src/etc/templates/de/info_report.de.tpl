Informationen �ber Liste [list->name]@[list->host] :

Betreff               : [subject]
[FOREACH o IN owner]
Verwalter             : [o->gecos] <[o->email]>
[END]
[FOREACH e IN editor]
Moderator             : [e->gecos] <[e->email]>
[END]
Abonnieren            : [subscribe]
Abonnement aufheben   : [unsubscribe]
Nachricht senden      : [send]
Liste der Mitglieder  : [review]
Antwort an            : [reply_to]
Maximale Gr��e        : [max_size]
[IF digest]
Auslese               : [digest]
[ENDIF]
Empfangsmodus     : [available_reception_mode]

[PARSE 'info']
