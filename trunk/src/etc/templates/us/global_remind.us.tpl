
[IF user->lang=fr]

Synth�se de vos abonnements (avec l'adresse [user->email]).

Ce message est strictement informatif, si vous ne souhaitez pas modifier
vos abonnements vous n'avez rien � entreprendre ; mais si vous souhaitez
vous d�sabonner de certaines listes, conservez bien ce message.

Voici pour chaque liste  une m�thode de d�sabonnement :


-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[FOREACH l IN lists]
[l]	mailto:[conf->sympa]?subject=sig%20[l]%20[user->email]
[END]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

[IF user->password]

Pour vous identifier sous  [conf->wwsympa_url] , votre adresse
de login est [user->email], votre mot de passe [user->passwd]

[ENDIF]

[ELSIF user->lang=es]
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
utilice su e-mail [user->email] y su contrase�a [user->passwd]

[ENDIF]

[ELSIF user->lang=it]
Riassunto delle sue iscrizioni (con l'indirizzo [user->email]).

Questo messaggio e' solamente informativo: se non vuole modificare
le sue iscrizioni, non deve fare nulla.

Ecco per ciascuna lista un link per cancellare l'iscrizione :


-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[FOREACH l IN list]
[l]     mailto:[conf->sympa]?subject=sig%20[l]%20[user->email]
[END]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

[IF user->password]

Per identificarsi su  [conf->wwsympa_url] , il suo
indirizzo di login e' [user->email], la sua password [user->passwd]

[ENDIF]

[ELSIF user->lang=pl]
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
u�yj swojego adresu email [user->email] i swojego has�a [user->passwd]

[ENDIF]

[ELSIF user->lang=cz]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

Souhrn Va�eho �lenstv� v konferenc�ch (p�i pou�it� adresy 
[user->email]).
Pokud se chcete odhl�sit z n�jak� konference, ulo�te si tuto zpr�vu.

Pro ka�dou konferenci je zde odkaz, kter�m se m��ete odhl�sit.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[FOREACH l IN lists]
[l]     mailto:[conf->sympa]?subject=sig%20[l]%20[user->email]
[END]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

[IF user->password]

Pro ov��en� toto�nosti na WWW rozhran� 
na adrese [conf->wwsympa_url]
pou�ijte svoji emailovou adresu [user->email] 
a svoje heslo [user->passwd]

[ENDIF]

[ELSE]
Summary of your subscription (using the e-mail [user->email]).
If you want to unsubscribe from some list, please save this mail.

Foreach list here is a mailto to use if you want to unsubscribe.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[FOREACH l IN lists]
[l]	mailto:[conf->sympa]?subject=sig%20[l]%20[user->email]
[END]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

[IF user->password]

In order to authenticate your self using wwsympa [conf->wwsympa_url]
use your e-mail [user->email] and your password [user->passwd]

[ENDIF]


