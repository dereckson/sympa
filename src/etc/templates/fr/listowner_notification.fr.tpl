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

[ELSIF type=automatic_bounce_management]
Subject: Gestion automatique des abonn�s en erreur de la liste [list->name]

[IF action=notify_bouncers]
Notre serveur ayant re�u de NOMBREUX rapports de non-remise, les [total] abonn�s list�s ci-dessous ont �t�
inform�s qu'ils risquaient d'�tre d�sabonn� de la liste [list->name] :
[ELSIF action=remove_bouncers]
Notre serveur ayant re�u de NOMBREUX rapports de non-remise, les [total] abonn�s list�s ci-dessous ont �t�
d�sabonn�s de la liste [list->name] :
[ELSIF action=none]
Notre serveur ayant re�u de NOMBREUX rapports de non-remise, les [total] abonn�s list�s ci-dessous ont �t�
marqu�s par Sympa comme des adresses gravement en erreur :
[ENDIF]

[FOREACH user IN  user_list]
[user]
[END]

[ENDIF]
