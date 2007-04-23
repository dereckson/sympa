
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

Powered by Sympa [conf->version] : http://listes.cru.fr/sympa/
