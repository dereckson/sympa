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

[ELSIF notice->msg=you_should_choose_a_password]
Pour choisir votre mot de passe, allez dans vos 'Pr�f�rences', depuis le menu sup�rieur

[ELSIF notice->msg=no_msg] 
Aucun message � mod�rer pour la liste [notice->list]

[ELSIF notice->msg=subscribers_update_soon]
La liste des membres de la liste sera g�n�r�e/mise � jour dans un moment (quelques minutes).

[ELSIF notice->msg=add_performed]
[notice->total] adresses ont �t� abonn�es

[ELSE]
[notice->msg]

[ENDIF]

<BR>
[END]




