[FOREACH notice IN notices]

[IF notice->msg=sent_to_owner]
Su petici�n ha sido enviada al propietario de la lista

[ELSIF notice->msg=performed]
[notice->action] : La operaci�n ha sido realizada con exito

[ELSIF notice->msg=list_config_updated]
El fichero de configuraci�n ha sido actualizado

[ELSIF notice->msg=upload_success] 
Fichero [notice->path] ha sido cargado con exito!

[ELSIF notice->msg=save_success] 
Fichero [notice->path] guardado

[ELSE]
[notice->msg]

[ENDIF]

<BR>
[END]




