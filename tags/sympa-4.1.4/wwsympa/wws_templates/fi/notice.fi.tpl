[FOREACH notice IN notices]

[IF notice->msg=sent_to_owner]
Pyynt�si on l�hetetty listan omistajalle

[ELSIF notice->msg=add_performed]
[notice->total] tilaajaa lis�tty

[ELSIF notice->msg=performed]
[notice->action] : toiminto onnistui

[ELSIF notice->msg=list_config_updated]
Asetustiedosto on p�ivitetty

[ELSIF notice->msg=upload_success] 
File [notice->path] ladattu onnistuneesti!

[ELSIF notice->msg=save_success] 
File [notice->path] tallennettu

[ELSIF notice->msg=password_sent]
Salasanasi on l�hetetty emailina

[ELSIF notice->msg=you_should_choose_a_password]
Valitaksesi salasana mene 'asetukset' sivulle, yl�valikon kautta.

[ELSIF notice->msg=no_msg] 
Ei viestej� hallittavana listalla [notice->list]

[ELSE]
[notice->msg]

[ENDIF]

<BR>
[END]




