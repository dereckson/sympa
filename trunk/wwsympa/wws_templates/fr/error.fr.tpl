<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF error_msg=unknown_action]
[error->action] : cette action est incorrecte

[ELSIF error_msg=unknown_list]
[error->list] : cette liste est inconnue

[ELSIF error_msg=already_login]
Vous �tes d�j� connect� avec l'adresse [error->email]

[ELSIF error_msg=no_email]
Vous devez fournir votre adresse e-mail

[ELSIF error_msg=incorrect_email]
L'adresse "[error->listname]" est incorrecte

[ELSIF error_msg=incorrect_listname]
"[error->email]" : nom de liste incorrect

[ELSIF error_msg=no_passwd]
Vous devez fournir votre mot de passe

[ELSIF error_msg=user_not_found]
"[error->email]" : utilisateur non reconnu

[ELSIF error_msg=user_not_found]
"[error->email]" n'est pas un abonn�

[ELSIF error_msg=passwd_not_found]
Aucun mot de passe pour l'utilisateur "[error->email]"

[ELSIF error_msg=incorrect_passwd]
Mot de passe saisi incorrect

[ELSIF error_msg=uncomplete_passwd]
Mot de passe saisi incomplet

[ELSIF error_msg=no_user]
Vous devez vous identifier

[ELSIF error_msg=may_not]
[error->action] : vous n'�tes pas autoris� � effectuer cette action
[IF ! user->email]
<BR>identifiez-vous (Login)
[ENDIF]

[ELSIF error_msg=no_subscriber]
La liste ne comporte aucun abonn�

[ELSIF error_msg=no_page]
Pas de page [error->page]

[ELSIF error_msg=no_filter]
Aucun filtre sp�cifi�

[ELSIF error_msg=file_not_editable]
[error->file] : fichier non �ditable

[ELSIF error_msg=already_subscriber]
Vous �tes d�j� abonn� � la liste [error->list] 

[ELSIF error_msg=user_already_subscriber]
[error->email] �tes d�j� abonn� � la liste [error->list] 

[ELSIF error_msg=sent_to_owner]
La demande a �t� soumise au gestionnaire de la liste

[ELSIF error_msg=failed]
L'op�ration a �chou�

[ELSIF error_msg=performed]
[error->action] : l'op�ration a �t� effectu�e

[ELSIF error_msg=not_subscriber]
Vous n'�tes pas abonn� � la liste [error->list]

[ELSIF error_msg=diff_passwd]
Les 2 mots de passe sont diff�rents

[ELSIF error_msg=missing_arg]
[error->argument] : param�tre manquant

[ELSIF error_msg=no_bounce]
Aucun bounce pour l'utilisateur [error->email]

[ELSIF error_msg=update_privilege_bypassed]
Vous avez �dit� un param�tre interdit: [error->pname]

[ELSIF error_msg=list_config_updated]
La configuration de la liste a �t� mise � jour

[ELSIF error_msg=config_changed]
Le fichier de configuration a �t� modifi� par [error->email]. Impossible d'appliquer vos modifications

[ELSIF error_msg=syntax_errors]
Erreurs de syntaxe des param�tres suivants :[error->params]

[ELSIF error_msg=no_such_document]
[error->path] : document inexistant 

[ELSIF error_msg=no_such_file]
[error->path] : fichier inexistant 

[ELSIF error_msg=empty_document] 
Impossible de lire [error->path] : document vide

[ELSIF error_msg=no_description] 
Aucune description sp�cifi�e

[ELSIF error_msg=no_content]
Echec : votre zone d'�dition est vide  

[ELSIF error_msg=no_name]
Aucun nom specifi�  

[ELSIF error_msg=incorrect_name]
[error->name] : nom incorrect  

[ELSIF error_msg = index_html]
Vous n'�tes pas autoris� � d�poser un fichier INDEX.HTML dans [error->dir] 

[ELSIF error_msg=synchro_failed]
Les donn�es ont chang� sur le disque. Impossible d'appliquer vos modifications 

[ELSIF error_msg=cannot_overwrite] 
Impossible d'�craser le fichier [error->path] : [error->reason]

[ELSIF error_msg=cannot_upload] 
Impossible de d�poser le  fichier [error->path] : [error->reason]

[ELSIF error_msg=cannot_create_dir] 
Impossible de cr�er le r�pertoire [error->path] : [error->reason]

[ELSIF error_msg=upload_success] 
Le fichier [error->path] a �t� d�pos�

[ELSIF error_msg=save_success] 
Fichier [error->path] sauvegard�

[ELSIF error_msg=full_directory]
Echec : le r�pertoire [error->directory] n'est pas vide  














[ELSE]
[error_msg]
[ENDIF]

