
Podsumowanie twojego uczestnictwa na li�cie (u�ywaj�c adresu [user->email]).
Je�eli chcesz si� wypisa� z listy zachowaj ten list.

Dla ka�dej listy mo�esz klikn�� na link �eby wypisa� sw�j adres.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[FOREACH l IN lists]
[l]     mailto:[conf->sympa]?subject=sig%20[l]%20[user->email]
[END]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

[IF user->password]

Aby zalogowa� si� do interfejsu WWW pod adresem [conf->wwsympa_url]
u�yj swojego adresu email [user->email] i swojego has�a [user->password]

[ENDIF]

