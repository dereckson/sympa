<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH error IN errors]

[IF error->msg=unknown_action]
[error->action] : tuntematon toiminto

[ELSIF error->msg=unknown_list]
[error->list] : tuntamaton lista

[ELSIF error->msg=already_login]
Olet jo kirjautuneena sis��n [error->email]

[ELSIF error->msg=no_email]
Anna email osoite

[ELSIF error->msg=incorrect_email]
Osoite "[error->email]" on v��r�

[ELSIF error->msg=incorrect_listname]
"[error->listname]" : v��r� listan nimi

[ELSIF error->msg=no_passwd]
Anna salasanasi

[ELSIF error->msg=user_not_found]
"[error->email]" : k�ytt�j� tuntematon

[ELSIF error->msg=passwd_not_found]
Ei salasanaa k�ytt�j�lle "[error->email]"

[ELSIF error->msg=incorrect_passwd]
Annettu salasana on v��r�

[ELSIF error->msg=incomplete_passwd]
Annettu salasana on puutteellinen

[ELSIF error->msg=no_user]
Sinun t�ytyy kirjautua

[ELSIF error->msg=may_not]
[error->action] : sinulla ei ole oikeuksia suorittaa t�t� toimenpidett�
[IF ! user->email]
<BR>sinun t�ytyy kirjautua
[ENDIF]

[ELSIF error->msg=no_subscriber]
Listalla ei ole tilaajia

[ELSIF error->msg=no_bounce]
Listalla ei ole tavoittamattomia tilaajia

[ELSIF error->msg=no_page]
Ei sivua [error->page]

[ELSIF error->msg=no_filter]
Puuttuva suodatin

[ELSIF error->msg=file_not_editable]
[error->file] : tiedosto ei ole muutettavissa

[ELSIF error->msg=already_subscriber]
Olet jo tilajaana listalla [error->list]

[ELSIF error->msg=user_already_subscriber]
[error->email] on jo tilaajana listalla [error->list] 

[ELSIF error->msg=failed_add]
K�ytt�j�n [error->user] lis��minen ep�onnistui

[ELSIF error->msg=failed]
[error->action]: toimepide ep�onnistui

[ELSIF error->msg=not_subscriber]
[IF error->email]
  Ei tilaajana: [error->email]
[ELSE]
Et ole tilaajana listalla [error->list]
[ENDIF]

[ELSIF error->msg=diff_passwd]
Salasanat eiv�t t�sm��

[ELSIF error->msg=missing_arg]
Puuttuva argumentti [error->argument]

[ELSIF error->msg=no_bounce]
Ei palaavia viestej� k�ytt�j�ll� [error->email]

[ELSIF error->msg=update_privilege_bypassed]
Muutit parametria ilman oikeuksia: [error->pname]

[ELSIF error->msg=config_changed]
Asetustiedostoa on muutettu [error->email] toimesta. Ei voida ottaa k�ytt��n muutoksia.

[ELSIF error->msg=syntax_errors]
Syntaksi virhe seuraavissa parametreissa: [error->params]

[ELSIF error->msg=no_such_document]
[error->path] : Tiedosto tai hakemisto ei olemassa

[ELSIF error->msg=no_such_file]
[error->path] : Tiedostoa ei olemassa

[ELSIF error->msg=empty_document] 
Luku ep�onnistui[error->path] : tyhj� dokumentti

[ELSIF error->msg=no_description] 
Kuvausta ei m��ritelty

[ELSIF error->msg=no_content]
Ep�onnistui: sis�lt� on tyhj�

[ELSIF error->msg=no_name]
Nime� ei m��ritelty

[ELSIF error->msg=incorrect_name]
[error->name] : v��r� nimi

[ELSIF error->msg = index_html]
Sinulla ei ole oikeuksia ladata INDEX.HTML:�� hakemistoon [error->dir] 

[ELSIF error->msg=synchro_failed]
Data on muuttunut levyll�. Muutoksia ei voida ottaa k�ytt��n.

[ELSIF error->msg=cannot_overwrite] 
Tiedostoa ei voida tallentaa [error->path] : [error->reason]

[ELSIF error->msg=cannot_upload] 
Tiedostoa ei voida ladata(upload) [error->path] : [error->reason]

[ELSIF error->msg=cannot_create_dir] 
Hakemistoa ei voida luoda [error->path] : [error->reason]

[ELSIF error->msg=full_directory]
Virhe : [error->directory] ei ole tyhj�

[ELSIF error->msg=init_passwd]
Et valinnut salasanaa, pyyd� muistutus alkuper�isest� salasanasta

[ELSIF error->msg=change_email_failed]
Email osoitteen muuttaminen listaan [error->list] ep�onnistui

[ELSIF error->msg=change_email_failed_because_subscribe_not_allowed]
Tilausosoitetta ei voitu muuttaa listalle  '[error->list]'
koska uudi osoitteesi ei ole sallittu tilaamaan listaa.

[ELSIF error->msg=change_email_failed_because_unsubscribe_not_allowed]
Tilausosoitetta ei voitu muuttaa listalle  '[error->list]'
koska sinulla ei ole oikeutta poistaa tilausta.

[ELSIF error->msg=shared_full]
Dokumenttiarkisto ylitti quota-rajan.

[ELSE]
[error->msg]
[ENDIF]

<BR>
[END]
