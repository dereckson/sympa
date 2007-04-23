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

Powered by Sympa [conf->version] : http://listes.cru.fr/sympa/
