<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF notice->msg=sent_to_owner]
V� po�adavek byl odesl�n spr�vci konference

[ELSIF notice->msg=add_performed]
p�id�no [notice->total] �len�

[ELSIF notice->msg=performed]
[notice->action] : akce skon�ila �sp�n�

[ELSIF notice->msg=list_config_updated]
Soubor s konfigurac� zm�n�n

[ELSIF notice->msg=upload_success] 
Soubor [notice->path] byl �sp�n� nahr�n!

[ELSIF notice->msg=save_success] 
Soubor [notice->path] ulo�en

[ELSIF notice->msg=password_sent]
Va�e heslo V�m bylo odesl�no emailem

[ELSIF notice->msg=you_should_choose_a_password]
Pro zm�nu hesla jd�te do "Nastaven�" v horn� �asti str�nky

[ELSE]
[notice->msg]

[ENDIF]

<BR>
[END]
