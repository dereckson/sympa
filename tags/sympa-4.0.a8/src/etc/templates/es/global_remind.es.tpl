
Sumario de su subscripci�n (con e-mail [user->email]).
Si usted quiere anular la subscripci�n de alguna lista, conserve este mail.

Por cada lista existe un m�todo para anular la subscripci�n:

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[FOREACH l IN lists]
[l]   mailto:[conf->sympa]?subject=sig%20[l]%20[user->email]
[END]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

[IF user->password]

Para autentificarse usando el interface web wwsympa [conf->wwsympa_url]
utilice su e-mail [user->email] y su contrase�a [user->password]

[ENDIF]

