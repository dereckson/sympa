From: [conf->email]@[conf->host]
To: Propri�taires de liste <[to]>
[IF type=arc_quota_exceeded]
Subject: Quota des archives de la liste "[list->name]" d�pass�

Le quota des archives de la liste [list->name]@[list->host] est
d�pass�. La taille des archives est de [size] octets. Les messages
de la liste ne sont plus archiv�s. 
Veuillez contacter listmaster@[conf->host]. 

[ELSIF type=arc_quota_95]
Subject: Alerte liste "[list->name]" : archives pleines � [rate]%

[rate2]
Les archives de la liste [list->name]@[list->host] ont atteint [rate]% 
de l'espace autoris�. Les archives de la liste utilisent [size] octets.

L'archivage des messages est toujours assur�, mais vous devriez contacter
listmaster@[conf->host]. 
[ENDIF]
