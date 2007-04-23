<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH error IN errors]

[IF error->msg=unknown_action]
[error->action]: ismeretlen parancs

[ELSIF error->msg=unknown_list]
[error->list]: ismeretlen lista

[ELSIF error->msg=already_login]
[error->email] c�mmel m�r bel�pt�l.

[ELSIF error->msg=no_email]
K�rlek add meg az e-mail c�medet.

[ELSIF error->msg=incorrect_email]
Nem megfelel� eimail c�m: "[error->email]" 

[ELSIF error->msg=incorrect_listname]
"[error->listname]": hib�san megadott listan�v

[ELSIF error->msg=no_passwd]
K�rlek add meg a jelszavadat.

[ELSIF error->msg=user_not_found]
"[error->email]": ismeretlen felhaszn�l�

[ELSIF error->msg=user_not_found]
"[error->email]" nem tagja a list�nak.

[ELSIF error->msg=passwd_not_found]
"[error->email]" felhaszn�l�nak nincsen jelszava.

[ELSIF error->msg=incorrect_passwd]
A megadott jelsz� nem megfelel�.

[ELSIF error->msg=uncomplete_passwd]
A megadott jelsz� nem teljes.

[ELSIF error->msg=no_user]
Be kell jelentkezned.

[ELSIF error->msg=may_not]
[error->action]: nincs jogod a m�velethez.
[IF ! user->email]
<BR>Be kell jelentkezned.
[ENDIF]

[ELSIF error->msg=no_subscriber]
A list�ra senkisem iratkozott fel.

[ELSIF error->msg=no_bounce]
A list�n nincsen visszapattant lev�l.

[ELSIF error->msg=no_page]
Nincs ilyen nev� oldal: [error->page]

[ELSIF error->msg=no_filter]
Hi�nyz� sz�r�

[ELSIF error->msg=file_not_editable]
[error->file]: az �llom�ny nem szerkeszthet�.

[ELSIF error->msg=already_subscriber]
M�r tagja vagy a(z) [error->list] list�nak.

[ELSIF error->msg=user_already_subscriber]
[error->email] m�r tagja a(z) [error->list] list�nak.

[ELSIF error->msg=failed_add]
Hiba a(z) [error->user] felhaszn�l� hozz�ad�sakor.

[ELSIF error->msg=failed]
[error->action]: hiba a m�velet elv�gz�sekor.

[ELSIF error->msg=not_subscriber]
Nem vagy a(z) [error->list] lista tagja.

[ELSIF error->msg=diff_passwd]
A megadott jelszavak nem egyeznek.

[ELSIF error->msg=missing_arg]
Hi�nyz� param�ter: [error->argument]

[ELSIF error->msg=no_bounce]
[error->email] felhaszn�l�nak nincsen visszapattant levele.

[ELSIF error->msg=update_privilege_bypassed]
Megfelel� jogosults�gok hi�ny�ban pr�b�lt�l meg m�dos�tani: [error->pname]

[ELSIF error->msg=config_changed]
A konfigur�ci�s �llom�ny megv�ltozott [error->email]. M�dos�t�saidat nem lehet elmenteni.

[ELSIF error->msg=syntax_errors]
Hib�san megadott parancs: [error->params]

[ELSIF error->msg=no_such_document]
[error->path]: K�nyvt�r nem tal�lhat�.

[ELSIF error->msg=no_such_file]
[error->path]: �llom�ny nem tal�lhat�.

[ELSIF error->msg=empty_document] 
Hiba a(z) [error->path] olvas�sakor: a dokumentum �res

[ELSIF error->msg=no_description] 
Nincs megadva le�r�s.

[ELSIF error->msg=no_content]
Hiba: �res a be�ll�t�sod

[ELSIF error->msg=no_name]
Nem lett megadva n�v.

[ELSIF error->msg=incorrect_name]
[error->name]: �rv�nytelen n�v.

[ELSIF error->msg = index_html]
Nincs jogosults�god �j INDEX.HTML �llom�ny felt�lt�s�re a(z) [error->dir] k�nyvt�rba.

[ELSIF error->msg=synchro_failed]
Az adatok megv�ltoztak. Nem lehet m�dos�t�saidat elmenteni.

[ELSIF error->msg=cannot_overwrite] 
[error->path] �llom�nyt nem lehet fel�l�rni : [error->reason]

[ELSIF error->msg=cannot_upload] 
Nem lehet a(z) [error->path] �llom�nyt fel�lteni: [error->reason]

[ELSIF error->msg=cannot_create_dir] 
Nem lehet l�trehozni a(z) [error->path] k�nyvt�rat: [error->reason]

[ELSIF error->msg=full_directory]
Hiba: [error->directory] k�nyvt�r nem �res. 

[ELSIF error->msg=init_passwd]
Nem adt�l meg jelsz�t, az eml�keztet� lek�rdez�s�vel kik�rheted a jelenlegi jelszavadat.

[ELSIF error->msg=change_email_failed]
A(z) [error->list] list�n nem siker�lt megv�ltoztatni az e-mail c�medet.

[ELSIF error->msg=change_email_failed_because_subscribe_not_allowed]
A(z) '[error->list]' list�n az e-mail c�medet nem siker�lt megv�ltoztatni, mert az �j c�meddel a list�n nem lehetn�l tag.

[ELSIF error->msg=change_email_failed_because_unsubscribe_not_allowed] 
A(z) '[error->list]' list�n az e-mail c�medet nem siker�lt megv�ltoztatni, mert a list�r�l nem lehet leiratkozni.

[ELSE]
[error->msg]
[ENDIF]

<BR>
[END]
