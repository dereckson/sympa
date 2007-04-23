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

Powered by Sympa [conf->version] : http://listes.cru.fr/sympa/
