
Yhteenveto tilauksestasi (k�ytt�en osoitetta [user->email]).
Jos haluat poistaa tilauksen joltain listalta, tallenna t�m� viesti.


Foreach lista t�ss� on osoite jota k�ytt�� jos haluat poistaa tilauksen.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[FOREACH l IN lists]
[l]	mailto:[conf->sympa]?subject=sig%20[l]%20[user->email]
[END]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

[IF user->password]

Kirjautuaksesi WWSympaan [conf->wwsympa_url]
k�yt� email osoitetta [user->email] ja salasanaa [user->password]


