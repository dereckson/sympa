
Sum�rio de sua subscri��o (com e-mail [user->email]).
Se voc� quiser anular a subscri��o de alguma lista, conserve este mail.

Por cada lista existe um m�todo para anular a subscri��o:

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[FOREACH l IN lists]
[l]   mailto:[conf->sympa]?subject=sig%20[l]%20[user->email]
[END]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

[IF user->password]

Para se autentificar usando o interface web wwsympa [conf->wwsympa_url]
utilize seu e-mail [user->email] y sua clave [user->password]

[ENDIF]

