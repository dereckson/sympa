<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF error_msg=unknown_action]
[error->action] : acci�n desconocida

[ELSIF error_msg=unknown_list]
[error->list] : lista desconocida

[ELSIF error_msg=already_login]
Vd. ya est� autentificado en el sistema como [error->email]

[ELSIF error_msg=no_email]
Por favor indique su email

[ELSIF error_msg=incorrect_email]
Direcci�n "[error->email]" es inv�lida

[ELSIF error_msg=incorrect_listname]
"[error->listname]" : nombre de lista incorrecto

[ELSIF error_msg=no_passwd]
Por favor, entre su contrase�a

[ELSIF error_msg=user_not_found]
"[error->email]" : usuario desconocido

[ELSIF error_msg=user_not_found]
"[error->email]" no es un subscriptor

[ELSIF error_msg=passwd_not_found]
No hay contrase�a del usuario "[error->email]"

[ELSIF error_msg=incorrect_passwd]
La contrase�a entrada no es correcta

[ELSIF error_msg=no_user]
Usted tiene que hacer un login

[ELSIF error_msg=may_not]
[error->action] : no est� permitido a realizar esta operaci�n

[ELSIF error_msg=no_subscriber]
La lista no tiene subscriptores

[ELSIF error_msg=no_bounce]
La lista no tiene subscriptores con errores

[ELSIF error_msg=no_page]
No hay p�gina [error->page]

[ELSIF error_msg=no_filter]
Filtro no encontrado

[ELSIF error_msg=file_not_editable]
[error->file] : fichero no editable

[ELSIF error_msg=already_subscriber]
Usted ya es un subscriptor de la lista [error->list]

[ELSIF error_msg=user_already_subscriber]
[error->email] ya es subscriptor de la lista [error->list] 

[ELSIF error_msg=sent_to_owner]
Su petici�n ha sido enviada al propietario de la lista

[ELSIF error_msg=failed]
La operaci�n ha fallado

[ELSIF error_msg=performed]
[error->action] : La operaci�n ha sido realizada con exito

[ELSIF error_msg=not_subscriber]
Usted no es un subscriptor de la lista [error->list]

[ELSIF error_msg=diff_passwd]
Las 2 contrase�as son diferentes

[ELSIF error_msg=missing_arg]
Falta un argumento [error->argument]

[ELSIF error_msg=no_bounce]
No hay errores del usuario [error->email]

[ELSIF error_msg=update_privilege_bypassed]
Ha cambiado un par�metro sin permisos : [error->pname]

[ELSIF error_msg=list_config_updated]
El fichero de configuraci�n ha sido actualizado

[ELSIF error_msg=config_changed]
El fichero de configuraci�n ha sido modificado por [error->email]. No se pueden hacer sus cambios

[ELSIF error_msg=syntax_errors]
Errores de sintaxis en los siguientes par�metros : [error->params]

[ELSIF error_msg=no_such_document]
[error->path] : No existe el fichero o el directorio

[ELSIF error_msg=no_such_file]
[error->path] : No existe el fichero

[ELSIF error_msg=empty_document] 
Unable to read [error->path] : documento vac�o

[ELSIF error_msg=no_description] 
No se especific� la descripci�n

[ELSIF error_msg=no_content]
Fallo : el contenido est� vac�o

[ELSIF error_msg=no_name]
No se especific� un nombre

[ELSIF error_msg=incorrect_name]
[error->name] : nombre incorrecto

[ELSIF error_msg = index_html]
Usted no est� autorizado a cargar INDEX.HTML en [error->dir] 

[ELSIF error_msg=synchro_failed]
Los datos han sido cambiados en el disco. No puedo hacer sus cambios

[ELSIF error_msg=cannot_overwrite] 
No puedo sobreescribir el fichero [error->path] : [error->reason]

[ELSIF error_msg=cannot_upload] 
No puedo cargar el fichero [error->path] : [error->reason]

[ELSIF error_msg=cannot_create_dir] 
No puedo cargar el directorio [error->path] : [error->reason]

[ELSIF error_msg=upload_success] 
Fichero [error->path] ha sido cargado con exito!

[ELSIF error_msg=save_success] 
Fichero [error->path] guardado

[ELSIF error_msg=full_directory]
Fallo : [error->directory] no est� vac�o

[ELSIF error_msg=password_sent]
Su contrase�a le ha sido enviado por correo

 

[ELSE]
[error_msg]
[ENDIF]
