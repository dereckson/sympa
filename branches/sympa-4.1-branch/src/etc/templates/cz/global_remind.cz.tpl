
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
a svoje heslo [user->password]

[ENDIF]

