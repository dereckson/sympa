From: [conf->email]@[conf->host]
To: Listmaster <[to]>
[IF type=request_list_creation]
Subject: Demande de creation de la liste "[list->name]"

Une demande de cr�ation pour la liste "[list->name]" a �t� faite par [email]

[list->name]@[list->host]
[list->subject]
[conf->wwsympa_url]/info/[list->name]

Pour activer/supprimer cette liste :
[conf->wwsympa_url]/get_pending_lists
[ELSIF type=virus_scan_failed]
Subject: Echec d�tection antivirale

L'appel � l'antivirus a �chou� lors du traitement du fichier suivant :
	[filename]

Le message d'erreur :
	[error_msg]
[error_msg]
[ENDIF]
