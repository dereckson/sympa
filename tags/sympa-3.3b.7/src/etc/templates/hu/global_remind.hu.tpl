
�rtes�t�s a feliratkoz�saidr�l ([user->email] c�mmel).
Ha valamelyik list�r�l le akarsz iratkozni, akkor mentsd el ezt a levelet.

Itt az �sszes list�hoz megtal�lod a leiratkoz�si c�met.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[FOREACH l IN lists]
[l]     mailto:[conf->sympa]?subject=sig%20[l]%20[user->email]
[END]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

[IF user->password]

A wwsympa [conf->wwsympa_url] bel�p�sn�l a(z) [user->email]
e-mail c�met �s [user->passwd] jelsz�t haszn�ld.

[ENDIF]
