[FOREACH notice IN notices]

[IF notice->msg=sent_to_owner]
La demande a �t� soumise au gestionnaire de la liste

[ELSIF notice->msg=performed]
[notice->action] : l'op�ration a �t� effectu�e

[ELSIF notice->msg=list_config_updated]
La configuration de la liste a �t� mise � jour

[ELSIF notice->msg=upload_success] 
Le fichier [notice->path] a �t� d�pos�

[ELSIF notice->msg=save_success] 
Fichier [notice->path] sauvegard�

[ELSE]
[notice->msg]

[ENDIF]

<BR>
[END]




