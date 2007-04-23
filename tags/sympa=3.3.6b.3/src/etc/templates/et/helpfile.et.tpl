              SYMPA -- Systeme de Multi-Postage Automatique
                  (Automaatne e-posti listide s�steem)

                            Kasutajajuhend


Sympa on e-posti listide haldamise tarkvara, mis v�imaldab lihtsalt
hallata listide liikmeid, arhiive ning modereerimist. 

K�ik k�sud sympale tuleb saada e-posti aadressile [conf->sympa]

E-posti teel Sympale saadetavad k�sud peavad olema kas kirja sisus v�i
teemareal. Kirja sisus saab sympale kirjutada ka mitut k�sku, selleks peab 
k�sk olema eraldi real. Kirja sisus olvatest k�skudest saab sympa aru ainult
siis, kui kiri on saadetud tavalise tekstina, mille mime t��biks on 
text/plain. Juhul kui teie e-postiprogramm ei saada kirju puhta tekstina,
saate Sympale k�ske saata teemareal.

Sympa k�sud on:

 HELp                        * Saadab teile sellesama abifaili
 INFO                        * Info listi kohta
 LISts                       * Selle serveri poolt hallatavte listide nimekiri
 REView <list>               * N�itab listi <list> lugejaid
 WHICH                       * N�itab, milliste listide liige te olete
 SUBscribe <list> <GECOS>    * Selle k�suga saab listi <list> liikmeks. 
                               <GECOS> kohale kirjutage t�iendav info enda 
			       kohta (n�iteks nimi)
 UNSubscribe <list> <EMAIL>  * Selle k�suga saab lahkuda listist <list>.
                               <EMAIL> asemele kirjutage teie aadress, mis on 
			       listis, juhul kui listis olev aadress erineb 
			       sellest aadressist, mis on teil From: real.
 UNSubscribe * <EMAIL>       * Analoogne eelmisega, ainult lahkute k�ikidest
                               listidest
 SET <list|*> NOMAIL         * Peatab listi(de)st kirjade tulemise, j��te
                               listi(de) liikmeks siiski edasi.
 SET <list|*> DIGEST         * Kirjad listi(de)st tulevad kokkuv�tetena.
 SET <list|*> SUMMARY        * Saate kirjadest vaid indeksi.
 SET <list|*> NOTICE         * Saate igast kirjast vaid teemarea. 

 SET <list|*> MAIL           * Saate listi normaalselt (kirjadena)
 SET <list|*> CONCEAL        * Saate varjata oma listi liikmestaatust
 SET <list|*> NOCONCEAL      * Saate oma liikmestaatuse n�htavaks teha


 INDex <list>                * Saate listi <list> arhiivifailide nimekirja 
 GET <list> <file>           * Saate faili <file> listi <list> arhiivist
 LAST <list>                 * Saate viimase kirja listist <list>
 INVITE <list> <email>       * Kutsute aadressi <email> liituma listiga <list>
 CONFIRM <key>               * Kinnitate listi kirja saamtist (s�ltub listi
                               seadetest)
 QUIT                        * N�itab, et k�sud on l�ppenud (signatuuri 
                               varjamiseks).

[IF is_owner]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
J�rgnevaid k�skusid saavad kasutada vaid listide omanikud ja moderaatorid:

 ADD <list> user@host First Last * Lisate kasutaja listi. 
 DEL <list> user@host            * Kustutae kasutaja listist.
 STATS <list>                    * Listi <list> statistika
 EXPire <list> <old> <delay>     * Algatab aegumisprotsessi listi <list>
                                   lugejate hulgas, kes ei ole kinnitanud oma
				   liikmestaatust <old> p�eva jooksul.
				   Lugejatel on <delay> p�eva aega kinnitada
				   oma lugejastaatust.
 EXPireINDex <list>              * N�itab k�esoleva aegumisprotsessi staatust
                                   listis <list>
 EXPireDEL <list>                * Peatab aegumisprotsessi listis <list>
 REMIND <list>                   * Saadab meeldetuletusteate igale listi 
                                   liikmele. (Nii saab teavitada listi liikmeid
				   nende tegelikest e-posti aadressidest lists)
[ENDIF]
[IF is_editor]

 DISTribute <list> <clef>        * Modereerimine: kirja aktsepteerimine 
 REJect <list> <clef>            * Modereerimine: kirja tagasi l�kkamine
 MODINDEX <list>                 * Modereerimine: modereeritavate kirjade
                                   nimekirja n�itamine.
[ENDIF]

Siin t��tab Sympa [conf->version] : http://listes.cru.fr/sympa/

