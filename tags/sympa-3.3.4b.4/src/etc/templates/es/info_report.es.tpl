Informaci�n acerca de la lista [list->name]@[list->host] :

Tema normal           : [subject]
[FOREACH o IN owner]
Propietario           : [o->gecos] <[o->email]>
[END]
[FOREACH e IN editor]
Moderador             : [e->gecos] <[e->email]>
[END]
Suscripci�n           : [subscribe]
Supresi�n             : [unsubscribe]
Enviando mensajes     : [send]
Lista de suscriptores : [review]
Respuesta a           : [reply_to]
Tama�o M�ximo         : [max_size]
[IF digest]
Resumen               : [digest]
[ENDIF]
Modo de recepci�n     : [available_reception_mode]

[PARSE 'info']
