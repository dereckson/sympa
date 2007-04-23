
              SYMPA -- Systeme de Multi-Postage Automatique
                       (Automatikus Levelez� Rendszer)

                                Felhaszn�l�i K�zik�nyv

SYMPA egy automatikus levelez�lista-kezel� program, mellyel a listakezel�st,
mint pl. a feliratkoz�sokat, moder�l�st �s arch�v�l�st lehet elv�gezni.

Minden parancsot a k�vetkez� email c�mre kell k�ldeni: [conf->sympa]

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
			       ha a jelenlegi c�med elt�r a nyilv�ntartott�l.
 
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
				    tags�gukat. A tagoknak <hat�rid�>-ben
				    megadott nap �ll rendelkez�s�kre ezt
				    p�tolni.
 EXPireINDex <lista>              * A <list�>-n jelenleg �rv�nyben lev�
				    meger�s�t�si folyamat megjelen�t�se
 EXPireDEL <lista>                * A <list�>-n l�v� meger�s�t�si folyamat
				    t�rl�se

 REMIND <lista>                   * Eml�keztet� lev�l elk�ld�se a <lista>
                                    �sszes tagj�nak. (�gy adhat� tudtukra,
                                    hogy milyen c�mmel vannak a list�n
                                    nyilv�ntartva.)
[ENDIF]
[IF is_editor]

 DISTribute <lista> <clef>        * Moder�l�s: lev�l enged�lyez�se
 REJect <lista> <clef>            * Moder�l�s: lev�l visszautas�t�sa
 MODINDEX <lista>                 * Moder�l�s: moder�l�sra v�r� levelek
				    megtekint�se

[ENDIF]

Powered by Sympa [conf->version] : http://listes.cru.fr/sympa/
