[IF  user->lang=fr]

              SYMPA -- Systeme de Multi-Postage Automatique
 
                       Guide de l'utilisateur


SYMPA est un gestionnaire de listes electroniques. Il permet d'automatiser
les fonctions de gestion des listes telles les abonnements, la moderation
et la gestion des archives.

Toutes les commandes doivent etre adressees a l'adresse electronique
[conf->sympa]

Il est possible de mettre plusieurs commandes dans chaque message : les
commandes doivent apparaitre dans le corps du message et chaque ligne ne
doit contenir qu'une seule commande. Sympa ignore le corps du message
si celui-ci n'est de type "Content-type: text/plain", mais m�me si vous
etes fanatique d'un agent de messagerie qui fabrique systematiquement des
messages "multipart" ou "text/html", les commandes placees dans le sujet
du messages sont reconnues.

Les commandes disponibles sont :

 HELp	                     * Ce fichier d'aide
 LISts	                     * Annuaire des listes geres sur ce noeud
 REView <list>               * Connaitre la liste des abonnes de <list>
 WHICH                       * Savoir � quelles listes on est abonn�
 SUBscribe <list> Prenom Nom * S'abonner ou confirmer son abonnement a la 
			       liste <list>
 SIGnoff <list|*> [user->email]    * Quitter la liste <list>, ou toutes les listes.
                               O� [user->email] est facultatif

			     Mise � jour du mode de reception:	
 SET <list|*> MAIL           * Reception de la liste <list> en mode normal
 SET <list|*> NOMAIL         * Suspendre la reception des messages de <list>
 SET <list|*> DIGEST         * Reception des message en mode compilation
 SET <list|*> SUMMARY        * Reception de la liste des messages uniquement
 SET <list|*> NOTICE         * Reception de l'objet des messages uniquement
 SET <list|*> TXT            * Reception uniquement au format texte pour les messages �mis 
			       conjointement en HTML et en texte simple.
 SET <list|*> HTML           * Reception uniquement au format HTML pour les messages �mis 
			       conjointement en HTML et en texte simple. 
 SET <list|*> URLIZE	     * Remplacement des attachements par une URL
 SET <list|*> NOT_ME         * Ne pas recevoir les messages dont je suis l'auteur


			     Mise � jour de la visibilite:	
 SET <list|*> CONCEAL        * Passage en liste rouge (adresse d'abonn� cach�e)
 SET <list|*> NOCONCEAL      * Adresse d'abonn� visible via REView

 INFO <list>                 * Informations sur une liste
 INDex <list>                * Liste des fichiers de l'archive de <list>
 GET <list> <fichier>        * Obtenir <fichier> de l'archive de <list>
 LAST <list>		     * Obtenir le dernier message de <list>
 INVITE <list> <email>       * Inviter <email> a s'abonner � <list>
 CONFIRM <clef>	 	     * Confirmation pour l'envoi d'un message
			       (selon config de la liste)
 QUIT                        * Indique la fin des commandes (pour ignorer 
                               une signature

[IF is_owner]
Commandes r�serv�es aux propri�taires de listes:
 
 ADD <list> user@host Prenom Nom * Ajouter un utilisateur a une liste
 DEL <list> user@host            * Supprimer un utilisateur d'une liste
 STATS <list>                    * Consulter les statistiques de <list>
 EXPire <list> <ancien> <delai>  * D�clanche un processus d'expiration pour
                                   les abonn�s � la liste <list> n'ayant pas
				   confirm� leur abonnement depuis <ancien>
				   jours. Les abonn�s ont <delai> jours pour
				   confirmer
 EXPireINDex <list>              * Connaitre l'�tat du processus d'expiration
                                   en cours pour la liste <list>
 EXPireDEL <list>                * D�sactive le processus d'espiration de la
                                   liste <list>

 REMind <list>                   * Envoi � chaque abonn� un message
                                   personnalis� lui rappelant
                                   l'adresse avec laquelle il est abonn�.
[ENDIF]

[IF is_editor]

Commandes r�serv�es aux mod�rateurs de listes :

 DISTribute <list> <clef>        * Mod�ration : valider un message
 REJect <list> <clef>            * Mod�ration : invalider un message
 MODINDEX <list>                 * Mod�ration : consulter la liste des messages
                                   � mod�rer
[ENDIF]

[ELSIF user->lang=it]

		  SYMPA -- Mailing List Manager

	     		Guida utente

SYMPA e' un gestore di liste di posta elettronica.
Permette di automatizzare le funzioni di gestione delle liste:
iscrizioni, cancellazioni, moderazione, archiviazione.

Tutti i comandi devono essere inviati all'indirizzo
  [conf->sympa]

E'  possibile  inserire piu' di un comando in ciascun messaggio:
i comandi devono essere scritti nel corpo del messaggio, uno per riga.

Il formato deve essere text/plain: se proprio siete fanatici dei
messaggi "multipart" o "text/html", potete inserire un comando
nell'oggetto del messaggio.

Elenco dei comandi:

  HELp                  * Questo file di istruzioni

  LISts                 * Lista delle liste gestite da questo server

  REView <list>         * Elenco degli iscritti

  WHICH                 * Mostra in quali liste sei iscritto

  SUBscribe <list> [Nome Cognome]
                        * Iscrizione

  SIGnoff <list|*> [user->email]
                        * Cancellazione dalla lista o da tutte le liste

  SET <list|*> NOMAIL   * Sospende la ricezione dei messaggi

  SET <list|*> DIGEST   * Ricezione dei messaggi in modo aggregato

  SET <list|*> SUMMARY  * Receiving the message index only

  SET <list|*> MAIL     * Ricezione dei messaggi in modo normale

  SET <list> CONCEAL    * Nasconde il proprio indirizzo dall'elenco
                          ottenuto col comando REV

  SET <list> NOCONCEAL  * Rende visibile il proprio indirizzo
                          nell'elenco ottenuto col comando REV

  INFO <list>           * Informazioni sulla lista

  INDex <list>          * Indice dei file di archivio

  GET <list> <file>     * Scarica il <file> dall'archivio

  LAST <list>           * Prende l'ultimo messaggio

  INVITE <list> <email> * Invita l'utente <email> a iscriversi

  CONFIRM <key>         * Conferma per l'invio di un messaggio (dipende
                          dalla configurazione della lista)

  QUIT                  * Fine dei comandi (per ignorare la firma)

[IF is_owner]
Comandi riservati ai gestori delle liste:

 ADD <list> user@host [Nome Cognome]
                        * Aggiunge l'utente

 DEL <list> user@host   * Cancella l'utente

 STATS <list>           * Consulta le statistiche

 EXPire <list> <old> <delay>
                        * Inizia un processo di scadenza per gli utenti
                          che non hanno confermato l'iscrizione da <old>
                          giorni.
                          Restano <delay> giorni per confermare.

 EXPireINDex <list>     * Mostra lo stato del processo di scadenza
                          corrente per la lista <list>

 EXPireDEL <list>       * Annulla il processo di scadenza per la lista

 REMIND <list>          * Invia a ciascun utente un messaggio
                          personalizzato per ricordare con quale
                          indirizzo e' iscritto
[ENDIF]

[IF is_editor]


Comandi riservati ai moderatori delle liste:

 DISTribute <list> <key>
                        * Moderazione: convalida di messaggio

 REJect <list> <key>    * Moderazione: rifiuto di messaggio

 MODINDEX <list>        * Moderazione: consultazione dell'elenco dei
                          messaggi da moderare
[ENDIF]

[ELSIF user->lang=de]

              SYMPA -- Systeme de Multi-Postage Automatique
                         (Automatisches Mailing System)

                             Benutzungshinweise


--------------------------------------------------------------------------------
SYMPA ist ein elektronischer Mailing-Listen-Manager, der Funktionen zur Listen-
verwaltung automatisiert, wie zum Beispiel Abonnieren, Moderieren und Verwalten 
von Mail-Archiven.

Alle Kommandos muessen an die Mail-Adresse [conf->sympa] geschickt werden.

Sie koennen mehrere Kommandos in einer Nachricht abschicken. Diese Kommandos
muessen im Hauptteil der Nachricht stehen und jede Zeile darf nur ein Kommando 
enthalten. Der Mail-Hauptteil wird ignoriert, wenn der Content-Type nicht 
text/plain ist. Sollten Sie ein Mail-Programm verwenden, das jede Nachricht 
als Multipart oder text/html sendet, so kann das Kommando alternativ in der 
Betreffzeile untergebracht werden.

Verfuegbare Kommandos:

 HELp                        * Diese Hilfedatei
 INFO                        * Information ueber die Liste
 LISts                       * Auflistung der verwalteten Listen
 REView <list>               * Anzeige der Abonnenten der Liste <list>
 WHICH                       * Anzeige der Listen, die Sie abonniert haben
 SUBscribe <list> <GECOS>    * Abonnieren bzw. Bestaetigen eines Abonnements
                               der Liste <list>, <GECOS> ist eine zusaetzliche
                               Information ueber den Abonnenten
 UNSubscribe <list> <EMAIL>  * Abbestellen der Liste <list>. <EMAIL> kann
                               optional angegeben werden. Nuetzlich, wenn
                               verschieden von Ihrer "Von:"-Adresse.
 UNSubscribe * <EMAIL>       * Abbestellen aller Listen

 SET <list|*> NOMAIL         * Abonnement der Liste <list> aussetzen
 SET <list|*> DIGEST         * Mail-Empfang im Kompilierungs-Modus
 SET <list|*> SUMMARY        * Receiving the message index only
 SET <list|*> MAIL           * Listenempfang von <list> im Normal-Modus
 SET <list|*> CONCEAL        * Bei Auflistung (REVIEW) Mail-Adresse nicht
                               anzeigen (versteckte Abonnement-Adresse)
 SET <list> NOCONCEAL        * Bei Auflistung (REVIEW) Mail-Adresse wieder
                               sichtbar machen

 INDex <list>                * Auflistung der Dateien im Mail-Archive <list>
 GET <list> <file>           * Datei <file> des Mail-Archivs <list> anfordern
 LAST <list>                 * Used to received the last message from <list>
 INVITE <list> <email>       * Invite user <email> for subscribtion in <list>
 CONFIRM <key>               * Bestaetigung fuer Gueltigkeit der Mail-Adresse
                               (haengt von Konfiguration der Liste ab)
 QUIT                        * Zeigt Ende der Kommandoliste an (wird verwendet
                               zum Ueberlesen der Signatur einer Mail)


[IF is_owner]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
Die folgenden Kommandos sind nur fuer Eigentuemer bzw. Moderatoren der Listen
zulaessig:

 ADD <list> user@host First Last * Benutzer der Liste <list> hinzufuegen
 DEL <list> user@host            * Benutzer von der Liste <list> entfernen
 STATS <list>                    * Statistik fuer <list> abrufen
 EXPire <list> <old> <delay>     * Ablauffrist fuer Liste <list> setzen fuer
                                   Abonnenten (Subscribers), die nicht inner-
                                   halb von <old> Tagen eine Bestaetigung
                                   schicken. Diese Ablauffrist beginnt erst
                                   nach <delay> Tagen (nach SUBSCRIBE).
 EXPireINDex <list>              * Anzeige des aktuellen Status fuer Ablauf-
                                   fristen der Liste <list>
 EXPireDEL <list>                * Ablauffrist fuer Liste <list> loeschen.

 REMIND <list>                   * Erinnerungsnachricht an jeden Abonnenten
                                   schicken (damit kann jedem Benutzer
                                   mitgeteilt werden, unter welcher
                                   Adresse er die Liste abonniert hat)
[ENDIF]
[IF is_editor]
 DIStribute <list> <clef>        * Moderation: Nachricht ueberpruefen
 REJect <list> <clef>            * Moderation: Nachricht ablehnen
 MODINDEX <list>                 * Moderation: Liste der Nachrichten der zu
                                   moderierenden Nachrichten
[ENDIF]

[ELSIF user->lang=es]
              SYMPA -- Systeme de Multi-Postage Automatique
                       (Sistema Automatico de Listas de Correo)

                                Gu�a de Usuario


SYMPA es un gestor de listas de correo electr�nicas que automatiza las funciones
habituales de una lista como la subscripci�n, moderaci�n y archivo de mensajes.

Todos los comandos deben ser enviados a la direcci�n [conf->sympa]

Se pueden poner m�ltiples comandos en un mismo mensaje. Estos comandos tienen que
aparecer en el texto del mensaje y cada l�nea debe contener un �nico comando.
Los mensajes se deben enviar como texto normal (text/plain) y no en formato HTML.
En cualquier caso, los mensajes en el sujeto del mensaje tambi�n son interpretados.


Los comandos disponibles son:

 HELp                        * Este fichero de ayuda
 INFO                        * Informaci�n de una lista
 LISts                       * Directorio de todas las listas de este sistema
 REView <lista>              * Muestra los subscriptores de <lista>
 WHICH                       * Muestra a qu� listas est� subscrito
 SUBscribe <lista> <GECOS>   * Para subscribirse o confirmar una subscripci�n
                               a <lista>.  <GECOS> es informaci�n adicional
                               del subscriptor (opcional).

 UNSubscribe <lista> <EMAIL> * Para anular la subscripci�n a <lista>.
                               <EMAIL> es opcional y es la direcci�n elec-
                               tr�nica del subscriptor, �til si difiere
                               de la de direcci�n normal "De:".

 UNSubscribe * <EMAIL>       * Para borrarse de todas las listas

 SET <lista> NOMAIL          * Para suspender la recepci�n de mensajes de <lista>
 SET <lista|*> DIGEST        * Para recibir los mensajes recopilados
 SET <lista|*> SUMMARY       * Receiving the message index only
 SET <lista|*> MAIL          * Para activar la recepci�n de mensaje de <lista>
 SET <lista|*> CONCEAL       * Ocultar la direcci�n para el comando REView
 SET <lista|*> NOCONCEAL     * La direcci�n del subscriptor es visible via REView

 INDex <lista>               * Lista el archivo de <lista>
 GET <lista> <fichero>       * Para obtener el <fichero> de <lista>
 LAST <lista>                * Usado para recibir el �ltimo mensaje enviado a <lista>
 INVITE <lista> <email>      * Invitaci�n a <email> a subscribirse a <lista>
 CONFIRM <key>               * Confirmaci�n para enviar un mensaje
                               (depende de la configuraci�n de la lista)
 QUIT                        * Indica el fin de los comandos


[IF is_owner]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-
Los siguientes comandos son unicamente para los propietarios o moderadores de las listas:

ADD <lista> <email> Nombre Apellido   * Para a�adir un nuevo usuario a <lista>
DEL <lista> <email>                   * Para elimiar un usuario de <lista>
STATS <lista>                         * Para consultar las estad�sticas de <lista>

EXPire <lista> <dias> <espera>        * Para comenzar un proceso de expiraci�n para
                                        aquellos subscriptores que no han confirmado 
                                        su subscripci�n desde hace tantos <dias>.
                                        Los subscriptores tiene tantos d�as de <espera> 
                                        para confirmar.

EXPireINDEx <lista>                   * Muestra el actual proceso de expiraci�n de <lista>
EXPireDEL <lista>                     * Desactiva el proceso de expiraci�n de <lista>

REMIND <lista>                        * Envia un mensaje a cada subscriptor (esto es una
                                        forma de recordar a cualquiera con qu� e-mail
                                        est� subscrito).

[ENDIF]
[IF is_editor]

 DISTribute <lista> <clave>           * Moderaci�n: para validar un mensaje
 REJect <lista> <clave>               * Moderaci�n: para denegar un mensaje
 MODINDEX <listaa>                    * Moderaci�n: consultar la lista de mensajes a moderar

[ENDIF]

[ELSIF user->lang=pl]
              SYMPA -- Systeme de Multi-Postage Automatique
                       (Automatyczny System Pocztowy)

	   		     Instrukcja obs�ugi


SYMPA jest automatem odbs�uguj�cym funkcj� zarz�dzania listami takie jak
zapisywanie, wypisywanie, moderacja i obs�uga archiw�w list dyskusyjnych.

Wszystkie polecenia musz� by� wysy�ane pod adres [conf->sympa]

W jednym li�cie mo�na umie�ci� wi�cej ni� jedn� komend�. Musz� si� one 
znajdowa� w tre�ci wiadomo�ci, po jednej na linijk�. Tre�� wiadomo�ci 
nie zostanie wykonana je�eli zawarto�� listu b�dzie inna ni� czysty tekst.
(Parametr Content-Type ustawiony na test/plain).
Pomimo tego ograniczenia polecenia mog� by� umieszczane w temacie wiadomo�ci.

Dost�pne polecenia:

 HELp                        * Ten plik pomocy
 INFO                        * Informacje o li�cie
 LISts                       * Spis list na tym serwerze 
 REView <lista>              * Lista zapisanych na list� <lista>
 WHICH                       * Na jakie listy jestem zapisany?
 SUBscribe <lista> <GECOS>   * Zapisz lub potwierd� zapisanie na list�
                               <lista>, <GECOS> to dodatkowe informacje 
                               jak imi� i nazwisko.

 UNSubscribe <lista> <EMAIL> * Wypisanie z listy <lista>.<EMAIL> nale�y
			       poda� je�eli adres b�dzie inny ni� w polu
			       nadawca tej wiadomo�ci. 
 UNSubscribe * <EMAIL>       * Wypisanie ze wszystkich list.

 SET <lista|*> NOMAIL        * Zawieszenie zapisania na list� <lista>
 SET <lista|*> DIGEST        * Ustaw tryb odbierania na DIGEST
 SET <lista|*> SUMMARY       * Odbi�r tylko spisu wiadomo�ci z listy
 SET <lista|*> MAIL          * Normalny tryb odbioru listy 
 SET <lista|*> CONCEAL       * Nie pokazuj mojego adresu na li�cie zapisanych
 SET <lista|*> NOCONCEAL     * Pokazuj m�j adres na li�cie zapisanych


 INDex <lista>               * Lista plik�w w archiwum
 GET <lista> <plik>          * Pobierz plik z archiwum listy
 LAST <lista>                * Pobierz ostatni list wys�any na list�
 INVITE <lista> <email>      * Zapro� <email> do zapisania na list� <lista>
 CONFIRM <key>               * Potwierd� wys�anie wiadomo�ci kluczem
			       (wymagane tylko je�li ustawienia tego wymagaj�)
 QUIT                        * Koniec bloku polece�

[IF is_owner]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
Polecenia zarezerwowane dla osoby administruj�cej lub moderuj�cej list�:

 ADD <lista> user@host Imi� Nazw  * Zapisz na list� adres
 DEL <lista> user@host            * Wypisz adres z listy
 STATS <lista>                    * Statystyki listy <lista>
 EXPire <lista> <old> <delay>     * Rozpocz�cie procesu wypisania adres�w
				    nie aktywnych na li�cie. Osoby kt�re nie
			            potwierdza�y zapisania od <old> dni, maj�
				    <delay> dni czasu aby to zrobi�.
				    Po up�ywie tego czasu zostan� wypisane.
 EXPireINDex <lista>              * Status procesu potwierdzania 
 EXPireDEL <lista>                * Wy��czenie procesu potwierdzania dla listy

 REMIND <lista>                   * Wy�lij polecenie przypomnienia do
				    wszystkich zapisanych. (jest to spos�b 
				    na przypomnienie o adresie z ktorego ka�da
				    osoba jest zapisana). 
[ENDIF]
[IF is_editor]

 DISTribute <lista> <clef>        * Moderacja: potwierd� wiadomo��
 REJect <lista> <clef>            * Moderacja: odrzu� wiadomo��
 MODINDEX <lista>                 * Moderacja: lista wiadomo�ci wymagaj�cych
				    potwierdzenia.
[ENDIF]

Obs�ugiwane przez Sympa [conf->version] : http://listes.cru.fr/sympa/

[ELSIF user->lang=cz]

              SYMPA -- Systeme de Multi-Postage Automatique
                       (Automatic Mailing System)

                          P��ru�ka u�ivatele


SYMPA elektronick� spr�vce konferenc�, kter� automatizuje funkce pro
spr�vu konference jako jsou p�ihl�en�, moderov�n� a archivace.

V�echny p��kazy se mus� pos�lat na adresu [conf->sympa]

M��ete um�stit vice p�ikaz� do jedn� zpr�vy. Tyto p��kazy mus� b�t
v t�le zpr�vy a ka�d� ��dek m��e obsahovat jenom jeden p��kaz. Pokud
nen� t�lo zpr�vy ve form�tu prost�ho textu, jsou p��kazy ignorov�ny,
v tom p��pad� mohou b�t i p��kazy v subjektu zpr�vy.

Dostupn� p��kazy jsou:

 HELp                        * Tato n�pov�da
 INFO                        * Informace o konferenci
 LISts                       * Seznam konferenc� na tomto po��ta�i
 REView <list>               * Zobrazi seznamu �len� konference <list>
 WHICH                       * Zobrazy konference, jich� jste �leny
 SUBscribe <list> <jmeno>    * Pro p�ihl�en� nebo jeho potvrzeni do
                               konference <list>, <jmeno> je volitelna
                               informace o �lenu konference.

 UNSubscribe <list> <EMAIL>  * Pro opu�t�n� konference <list>.
                               <EMAIL> je voliteln� emailova adresa,
                               vhodn�, pokud se li�� od Va�� adresy
                               v poli "From:" .

 UNSubscribe * <EMAIL>       * Pro opu�t�n� v�ech konferenc�.

 SET <list|*> NOMAIL         * Pro potla�en� p�ij�m�n� zpr�v z konference <list>
 SET <list|*> DIGEST         * P�ij�m�n� zprav v re�imu shrnut�
 SET <list|*> SUMMARY        * P�ij�m�n� pouze indexu zpr�v
 SET <list|*> NOTICE         * P�ij�m�n� pouze subjekt� zpr�v

 SET <list|*> MAIL           * Nastav� p��jem zpr�v z konference <list> do norm�ln�ho re�imu
 SET <list|*> CONCEAL        * Pro skryt� ze seznamu konference (skryt� adresa)
 SET <list|*> NOCONCEAL      * Adresa bude dostupn� p�es p��kaz REView


 INDex <list>                * Seznam souboru z arch�vu konference <list>
 GET <list> <file>           * Pro z�sk�n� souboru <file> z arch�vu konference <list>
 LAST <list>                 * Pro z�sk�n� posledn� zpr�vy z konference <list>
 INVITE <list> <email>       * Pozvat <email> k p�ihl�en� do konference <list>
 CONFIRM <key>               * Potvrzen� pro odesl�n� zpr�vy (z�le��
                               na konfiguraci konference)
 QUIT                        * Ozna�uje konec p��kazu (pro ignorov�n� podpisu)

[IF is_owner]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
N�sleduj�c� p��kazy jsou dostupn� pouze spr�vc�m nebo moder�tor�m konference:

 ADD <list> user@host First Last * Pro p�id�n� u�ivatele do konference
 DEL <list> user@host            * Pro smaz�n� u�ivatele z konference
 STATS <list>                    * Statistika konference <list>
 EXPire <list> <old> <delay>     * Pro spu�t�n� expira�n�ho procesu pro
                                   u�ivatele konference <list>,
                                   kte�� nepotvrdili sv� p�ihl�en� u�
                                   <old> dn�. �lenov� maj� <delay> dn�
                                   pro potvrzen�.
 EXPireINDex <list>              * Zobraz� aktu�ln� stav expirace pro <list>
 EXPireDEL <list>                * Pro zru�en� procesu expirace pro <list>

 REMIND <list>                   * Pro zasl�n� upozorn�n� ka�d�mu
                                   �lenu (toto je zp�sob, jak je informovat
                                   o jejich adrese v konferenci).

[ENDIF]
[IF is_editor]

 DISTribute <list> <clef>        * Moderov�n�: potvrzen� zpr�vy
 REJect <list> <clef>            * Moderov�n�: odm�tnut� zpr�vy
 MODINDEX <list>                 * Moderov�n�: z�sk�n� seznamu zpr�v
                                   �ekaj�c�ch na moderov�n�

[ENDIF]

[ELSIF user->lang=hu]

              SYMPA -- Systeme de Multi-Postage Automatique
                       (Automatikus Levelez� Rendszer)

                                Felhasz�l�i K�nyv

SYMPA egy automatikus levelez�lista-kezel� program, mellyel a listakezel�st,
mint pl. a feliratkoz�sokat, moder�l�st �s arch�v�l�st lehet elv�gezni.

Az �sszes email parancsot a k�vetkez� c�mre kell k�ldeni: [conf->sympa]

Egy lev�lben t�bb parancsot is meg lehet adni. A parancsokat a lev�l 
t�rzs�ben, soronk�nt egyes�vel kell megadni. A lev�l t�rzse csak akkor
ker�l feldologz�sra, ha az sima sz�veges form�tum�m, vagyis a Content-Type
text/plain. A program k�pes a lev�l t�rgy�ban megadott email parancsok 
�rtelmez�s�re, amely n�h�ny levelez�kliens haszn�lat�n�l el�fordulhat.

Az alkalmazhat� parancsok a k�vetkez�k:

 HELp                        * Ez a s�g�
 INFO                        * Inform�ci� adott list�r�l
 LISts                       * A szerveren m�k�d� levelez�list�k sora
 REView <lista>              * A <lista> tagjainak sora
 WHICH                       * Megmondja mely list�knak vagy tagja
 SUBscribe <lista> <GECOS>   * Feliratkoz�s vagy annak meger�s�t�se a
			       <list�>-ra. <GECOS> kieg�sz�t� inform�ci�kat
			       tartalmazhat a feliratkoz�r�l.

 UNSubscribe <lista> <EMAIL> * T�rl�s a <list�>-r�l. <EMAIL> az az email 
			       c�m, amellyel a lista tagja vagy, hasznos
			       ha a jelenlegi c�med elt�r a nyilv�ntarott�l.
 
 UNSubscribe * <EMAIL>       * T�rl�s az �sszes list�r�l.

 SET <lista|*> NOMAIL        * Lev�lfogad�s sz�neteltet�se a <list�>-r�l
 SET <lista|*> DIGEST        * Levelek fogad�sa egyben (digestk�nt)
 SET <lista|*> SUMMARY       * Csak a levelek list�j�nak fogad�sa
 SET <lista|*> NOTICE        * Csak a levelek t�rgysor�nak fogad�sa

 SET <lista|*> MAIL          * Lev�lfogad�s <list�>-r�l hagyom�nyos m�don
 SET <lista|*> CONCEAL       * C�med elrejt�se (titkos lesz az email c�med)
 SET <lista|*> NOCONCEAL     * C�med megjelenik a REView parancs kiemenet�ben


 INDex <lista>               * <lista> arch�vum tartalm�nak lek�r�se
 GET <lista> <file>          * <lista> arch�vum�b�l <file> lek�r�se
 LAST <lista>                * <lista> utols� �zenet�nek lek�r�se
 INVITE <lista> <email>      * <email> felk�r�se a <list�>-hoz csatlakoz�sra 
 CONFIRM <kulcs>             * �zenet megjelen�s�nek meger�s�t�s�hez sz�ks�ges
			       kulcs (lista be�ll�t�s�t�l f�gg haszn�lata)
 QUIT                        * A megadott parancsok feldolgoz�s�nak befejez�se
			       (az al��r�s �gy nem ker�l feldolgoz�sra) 

[IF is_owner]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
Parancsok csak a lista tulajdonos�nak vagy szerkeszt�j�nek:

 ADD <lista> user@host Kn�v Vn�v  * Tag hozz�ad�sa a list�hoz
 DEL <lista> user@host            * Tag t�rl�se a list�r�l
 STATS <lista>                    * <lista> statisztik�j�nak megtekint�se
 EXPire <lista> <nap> <hat�rid�>  * Azon tagok �rtes�t�se a <list�>-n akik 
			            <nap> �ta nem er�s�tett�k meg lista-
				    tag�sgukat. A tagoknak <hat�rid�>-ben
				    megadott nap �ll rendelkez�s�kre ezt
				    p�tolni.
 EXPireINDex <lista>              * A <list�>-n jelenleg �rv�nyben lev�
				    meger�s�t�si folyamat megjelen�t�se
 EXPireDEL <lista>                * A <list�>-n l�v� meger�s�t�si folyamat
				    t�rl�se

 REMIND <lista>                   * Send a reminder message to each
                                   subscriber (this is a way to inform
                                   anyone what is his real subscribing
                                   email).
[ENDIF]
[IF is_editor]

 DISTribute <lista> <clef>        * Moder�l�s: lev�l enged�lyez�se
 REJect <lista> <clef>            * Moder�l�s: lev�l visszautas�t�sa
 MODINDEX <lista>                 * Moder�l�s: moder�l�sra v�r� levelek
				    megtekint�se

[ENDIF]

[ELSIF user->lang=pt]
              SYMPA -- Systeme de Multi-Postage Automatique
                       (Sistema Autom�tico de Listas de Correio)

                                Guia de Usu�rio


SYMPA � um gestor de listas de correio eletr�nicas que automatiza as fun��es
freq�entes de uma lista como a subscri��o, modera��o e arquivo de mensagens.

Todos os comandos devem ser enviados a o endere�o [conf->sympa]

Podem se colocar m�ltiplos comandos numa mesma mensagem. Estes comandos tem que
aparecer no texto da mensagem e cada l�nea deve conter um �nico comando.
As mensagens devem se enviar como texto normal (text/plain) e n�o em formato HTML.
Em qualquer caso, os comandos no tema da mensagem tamb�m s�o interpretados.


Os comandos dispon�veis s�o:

HELp                        * Este ficheiro de ajuda
INFO                        * Informa��o de uma lista
LISts                       * Diret�rio de todas as listas de este sistema
REView <lista>              * Mostra os subscritores de <lista>
WHICH                       * Mostra a que listas est� subscrito
SUBscribe <lista> <GECOS>   * Para se subcribir ou confirmar uma subscri��o
                               a <lista>.  <GECOS> e informa��o adicional
                               do subscritor (opcional).

UNSubscribe <lista> <EMAIL> * Para anular uma subscri��o a <lista>.
                               <EMAIL> e opcional, e o endere�o elec-
                               tr�nico do subscritor, �til si difere
                               do endere�o normal "De:".

UNSubscribe * <EMAIL>       * Para se borrar de todas as listas

SET <lista> NOMAIL          * Para suspender a recep��o das mensagens de <lista>
SET <lista|*> DIGEST        * Para receber as mensagens recopiladas
SET <lista|*> SUMMARY       * Para s� receber o �ndex das mensagens 
SET <lista|*> MAIL          * Para ativar a recep��o das mensagens de <lista>
SET <lista|*> CONCEAL       * Ocultar a endere�o para o comando REView
SET <lista|*> NOCONCEAL     * O endere�o do subscritor e vis�vel via REView

INDex <lista>               * Lista o arquivo de <lista>
GET <lista> <ficheiro>      * Para obter o <ficheiro> de <lista>
LAST <lista>                * Usado para receber a �ltima mensagem enviada a <lista>
INVITE <lista> <email>      * Convida <email> a se subscribir a <lista>
CONFIRM <key>               * Confirma��o para enviar uma mensagem
(depende da configura��o da lista)
QUIT                        * Indica o final dos comandos


[IF is_owner]%)
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-
Os seguintes comandos s�o unicamente para os propriet�rios ou moderadores das listas:

ADD <lista> <email> Nome Sobrenome     * Para adicionar um novo usu�rio a <lista>
DEL <lista> <email>                   * Para eliminar um usu�rio da <lista>
STATS <lista>                         * Para consultar as estat�sticas da <lista>

EXPire <lista> <dias> <espera>        * Para iniciar um processo de expira��o para aqueles subscritores que n�o tem confirmado 
sua subscri��o desde tantos <dias>.
Os subscritores tem tantos dias de <espera> 
para confirmar.

EXPireINDEx <lista>                   * Mostra o atual processo de expira��o da <lista>
EXPireDEL <lista>                     * Desativa o processo de expira��o da <lista>

REMIND <lista>                        * Envia uma mensagem a cada subscritor (isto � um jeito para qualquer se lembrar com qu� e-mail est� subscrito).

[ENDIF]
[IF is_editor])

DISTribute <lista> <clave>           * Modera��o: para validar uma mensagem
REJect <lista> <clave>               * Modera��o: para denegar uma mensagem
MODINDEX <lista>                     * Modera��o: consultar a lista das mensagens a moderar

[ENDIF]

[ELSE]

              SYMPA -- Systeme de Multi-Postage Automatique
                       (Automatic Mailing System)

                                User's Guide


SYMPA is an electronic mailing-list manager that automates list management
functions such as subscriptions, moderation, and archive management.

All commands must be sent to the electronic address [conf->sympa]

You can put multiple commands in a message. These commands must appear in the
message body and each line must contain only one command. The message body
is ignored if the Content-Type is different from text/plain but even with
crasy mailer using multipart and text/html for any message, commands in the
subject are recognized.

Available commands are:

 HELp                        * This help file
 INFO                        * Information about a list
 LISts                       * Directory of lists managed on this node
 REView <list>               * Displays the subscribers to <list>
 WHICH                       * Displays which lists you are subscribed to
 SUBscribe <list> <GECOS>    * To subscribe or to confirm a subscription to
                               <list>, <GECOS> is an optional information
                               about subscriber.

 UNSubscribe <list> <EMAIL>  * To quit <list>. <EMAIL> is an optional 
                               email address, usefull if different from
                               your "From:" address.
 UNSubscribe * <EMAIL>       * To quit all lists.

 SET <list|*> NOMAIL         * To suspend the message reception for <list>
 SET <list|*> DIGEST         * Message reception in compilation mode
 SET <list|*> SUMMARY        * Receiving the message index only
 SET <list|*> NOTICE         * Receiving message subject only
 SET <list|*> TXT            * Receiving only text/plain part of messages send in both
			       text/plain and in text/html format.
 SET <list|*> HTML           * Receiving only text/html part of messages send in both
			       text/plain and in text/html format.
 SET <list|*> URLIZE         * Attachments are replaced by and URL.
 SET <list|*> NOT_ME         * No copy is sent to the sender of the message


 SET <list|*> MAIL           * <list> reception in normal mode
 SET <list|*> CONCEAL        * To become unlisted (hidden subscriber address)
 SET <list|*> NOCONCEAL      * Subscriber address visible via REView


 INDex <list>                * <list> archive file list
 GET <list> <file>           * To get <file> of <list> archive
 LAST <list>                 * Used to received the last message from <list>
 INVITE <list> <email>       * Invite <email> for subscribtion in <list>
 CONFIRM <key>               * Confirmation for sending a message (depending
                               on the list's configuration)
 QUIT                        * Indicates the end of the commands (to ignore a
                               signature)

[IF is_owner]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
The following commands are available only for lists's owners or moderators:

 ADD <list> user@host First Last * To add a user to a list
 DEL <list> user@host            * To delete a user from a list
 STATS <list>                    * To consult the statistics for <list>
 EXPire <list> <old> <delay>     * To begin an expiration process for <list>
                                   subscribers who have not confirmed their
                                   subscription for <old> days. The
                                   subscribers have <delay> days to confirm
 EXPireINDex <list>              * Displays the current expiration process
                                   state for <list>
 EXPireDEL <list>                * To de-activate the expiration process for
                                   <list>

 REMIND <list>                   * Send a reminder message to each
                                   subscriber (this is a way to inform
                                   anyone what is his real subscribing
                                   email).
[ENDIF]
[IF is_editor]

 DISTribute <list> <clef>        * Moderation: to validate a message
 REJect <list> <clef>            * Moderation: to reject a message
 MODINDEX <list>                 * Moderation: to consult the message list to
                                   moderate
[ENDIF]
[ENDIF]

Powered by Sympa [conf->version] : http://listes.cru.fr/sympa/

