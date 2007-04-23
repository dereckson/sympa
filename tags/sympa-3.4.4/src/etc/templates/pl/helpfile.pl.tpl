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

