<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH p IN param]
<A NAME="[p->NAME]">
<B>[p->title]</B> ([p->NAME]) :
<DL>
<DD>
[IF p->NAME=subject]
C'est une ligne de texte qui appara�t en sous-titre dans la page de pr�sentation de la liste, et qui accompagne le nom de la liste dans le tableau r�capitulatif des listes. La limitation � une ligne ne permet �videmment pas une pr�sentation d�taill�e.
Pour cela, il faut utiliser la page de pr�sentation de la liste et le champs &quot;info&quot; inclus dans certains messages de service (voir les rubriques
d'aides correspondantes).
[ELSIF p->NAME=visibility]
<p>Ce param�tre d�termine le comportement du robot en r�ponse � la commande LISTS d'un non abonn�. Il d�termine aussi les r�gles d'acc�s d'un non
abonn� � la page de pr�sentation de votre liste sur l'interface web ([conf->wwsympa_url]).
Il ne d�termine pas <i>l'aspect </i>de la page de pr�sentation, lequel est d�fni par les param�tres <font color="#800000">mode d'abonnement</font> et <font color="#800000">listes des abonn�s</font> (voir l'aide sp�cifique � ces param�tres).</p>
<p>Le param�tre visibilit� est d�fini ind�pendamment du mode d'abonnement � la liste. Cependant, dans la majorit� des cas, il semble logique de mettre les
listes � abonnement libre (open et open_notify) en option noconceal, et les listes � abonnement ferm� (closed) en option conceal. Si votre liste a le mode
d'abonnement owner, vous pourrez la classer en conceal ou noconceal suivant le degr� de publicit� que vous souhaitez lui donner.</p>
<p><font color="#800000"><b>noconceal&nbsp; </b></font>(non confidentielle) : le nom de votre liste et son sujet apparaissent dans la r�ponse � la commande
LISTS, m�me si l'�metteur de la commande n'est pas abonn� � la liste. De m�me, dans l'interface web, le menu &quot;listes publiques&quot; fera
appara�tre votre liste m�me si le visiteur effectue une connexion anonyme.&nbsp;</p>
<p><font color="#800000"><b>conceal&nbsp; </b></font>(confidentielle) : le nom de votre liste n'appara�t pas dans la r�ponse � la commande LISTS d'un non
abonn�, ni dans le menu &quot;listes publiques&quot; de l'interface web, � moins que le visiteur soit abonn� � votre liste et �tablisse une connexion
non anonyme. Autrement dit, il vous appartient de faire vous-m�me la publicit� de votre liste. Remarquez que le param�tre conceal<font color="#800000">&nbsp;</font> ne s'applique pas aux propri�taires et aux abonn�s de la liste. Ainsi, si vous envoyez la commande LISTS sous votre adresse de propri�taire, vous verrez appara�tre le nom de votre liste dans la r�ponse du robot, que votre liste soit publique ou nom.<br>
<font color="#800000"><i>Important</i></font> : m�me si la liste est d�clar�e conceal, il est possible d'obtenir sa page de pr�sentation sur le web, � condition de conna�tre par ailleurs le nom de la liste. <br>Celle-ci se trouve � l'adresse : [conf->wwsympa_url]/info/nom_de_la_liste.<br>
Il&nbsp; y a peu de chances qu'une personne ne connaissant pas le nom de la liste tombe sur cette page; il vaut mieux cependant pr�voir un texte de
pr�sentation. Si la personne n'est pas abonn�e, elle n'aura pas d'acc�s � d'autres renseignements que ceux que vous aurez ainsi affich�s.</p>
[ELSIF p->NAME=info]
  Indique qui peut consulter la page d'information (page d'accueil) de la
  liste.
[ELSIF p->NAME=subscribe]
  <p>Vous pouvez&nbsp; d�finir le mode d'abonnement � votre liste, celui-ci r�gle la r�ponse du robot � une demande d'abonnement (commande SUBscribe)
ou de d�sabonnement (commande SIGoff). Le comportement est le m�me si les demandes sont faites par l'interm�diaire de l'interface web.</p>
<p><font color="#800000"><b>open</b></font> : l'abonnement est r�alis� d�s r�ception d'une commande SUB ou par simple clic sur le bouton
&quot;abonnement&quot; de l'interface web. Si vous adoptez ce mode d'abonnement avec une liste non mod�r�e, surveillez attentivement les messages post�s sur
la liste pour �viter toute d�rive.&nbsp;</p>
<p><b><font color="#800000">open_notify</font></b> : ce mode est semblable au pr�c�dent. La seule diff�rence est que vous serez inform� par e-mail de
l'inscription de chaque nouvel abonn�.</p>
<p><b><font color="#800000">owner</font></b> :<b> </b>seuls les propri�taires peuvent proc�der aux abonnements. La commande SUB ou le clic sur le bouton
&quot;abonnement&quot;&nbsp; ne provoquent pas l'abonnement automatique; le demandeur est inform� que sa demande est envoy�e aux propri�taires de la
liste. Pour rendre l'abonnement effectif, ceux-ci devront utiliser la commande ADD&nbsp; ou l'interface web. Ce mode est recommand� pour les listes non
mod�r�es.</p>
<p><font color="#800000"><b>closed</b></font> : seuls les propri�taires peuvent proc�der aux abonnements. A la diff�rence du mode pr�c�dent, la commande SUB
ne transmet pas de demande d'abonnement aux propri�taires. L'�metteur de la commande SUB est inform� que les abonnements � la liste sont ferm�s. Dans l'interface
web, le bouton &quot;abonnement &quot; est remplac� par la mention :&quot;Abonnements ferm�s&quot;. </p>

[ELSIF p->NAME=add]
  Indique qui (en dehors des abonn�s eux-m�mes) peut directement inscrire des
  abonn�s � la liste. Ce droit est habituellement r�serv� au propri�taire de la
  liste.
[ELSIF p->NAME=unsubscribe]
  D�finit les conditions requises pour se d�sabonner de cette liste. Dans la majorit� des cas,
  le d�sabonnement devrait �tre disponible pour les abonn�s uniquement, avec
  confirmation, pour permettre � tout abonn� d�sireux de quitter une liste de
  pouvoir le faire, en �vitant qu'un tiers puisse d�sabonner quelqu'un � son
  insu.<br>
  La valeur correspondant � ce r�glage est "auth".<br>
  Si le propri�taire de la liste d�sire �tre inform� par mail lorsqu'un abonn�
  quitte la liste, la valeur � choisir est "auth_notify".
[ELSIF p->NAME=del]
  Indique qui (en dehors des abonn�s eux-m�mes) peut directement supprimer des
  abonn�s de la liste. Ce droit est habituellement r�serv� au propri�taire de la
  liste.
[ELSIF p->NAME=owner]
<p><font color="#800000"><b>Les propri�taires</b></font> ou gestionnaires sont responsables de la gestion des abonn�s de la liste. Ils peuvent consulter le
fichier des abonn�s, ajouter une adresse ou la supprimer soit par courrier soit par l'interface web. Si vous �tes propri�taire privil�gi�, vous pouvez d�signer d'autres propri�taires en �crivant simplement leur adresse dans un des champs. Pour supprimer un propri�taire, effacez le champ correspondant.</p>

<p><font color="#800000"><b>Les propri�taires privil�gi�s</b></font> peuvent, en plus, �diter les messages de service de la liste, d�finir certains
param�tres, d�signer d'autres propri�taires ou des mod�rateurs. Pour des raisons de s�curit�, il ne peut y avoir qu'un propri�taire privil�gi� par
liste. De plus, son adresse n'est pas �ditable par interface web. Si vous d�sirez modifier une adresse de propri�taire privil�gi�, adressez-vous au listmaster.</p>

[ELSIF p->NAME=send]
<p>Ce param�tre d�finit la fa�on dont les messages envoy�s � la liste sont trait�s ; la liste ci-dessous n'est pas exhaustive.</p>

<p><b><font color="#800000">public :</font></b> tous les messages adress�s � la liste, que le contributeur soit abonn� ou non, sont diffus�s � tous les
abonn�s. Il n'y a pas de mod�ration. Comme vous n'avez aucun contr�le a priori sur l'auteur du message et sur le contenu, vous ne devez utiliser ce mode
qu'avec prudence et en aucun cas avec une liste � abonnement libre. Exemple d'utilisation : r�alisation d'une enqu�te dont le d�pouillement sera assur�
par un groupe de personnes abonn�es � la liste et bien connues de vous.</p>

<p><font color="#800000"><b>private :</b></font> seuls les abonn�s peuvent poster un message. Il n'y a pas de mod�ration. Ce mode est recommand� si vous
voulez animer une liste non mod�r�e. En effet, l'abonnement est une d�marche volontaire ; tout abonn� est r�put� avoir pris connaissance du sujet et des
r�gles de fonctionnement de votre liste dans la page de pr�sentation, dans le&nbsp; message de bienvenue adress� aux nouveaux abonn�s ou dans les
messages de rappel d'abonnement.</p>

<p><font color="#800000"><b>editorkeyonly&nbsp; :</b></font> Les messages adress�s � la liste, que le contributeur soit abonn� ou non, sont envoy�s
d'abord aux mod�rateurs. Ceux-ci ne peuvent pas modifier les messages : ils peuvent seulement les accepter ou les rejeter. Dans un cas comme dans l'autre,
le message est retir� de la file d'attente, ce qui revient � dire que le premier mod�rateur qui prend une d�cision l'impose aux autres. Si aucun
mod�rateur ne prend de d�cision dans un d�lai d'une semaine suivant l'arriv�e du message, ce dernier est d�truit sans �tre diffus�. Notez que
les messages post�s par les mod�rateurs sont �galement soumis � la mod�ration.<br>

<p><font color="#800000"><b>editorkey&nbsp; :</b></font> Ce mode est identique � editorkeyonley, � la diff�rence que les messages des mod�rateurs sont
diffus�s directement. Cela offre une plus grande souplesse d'utilisation aux mod�rateurs, au prix d'une s�curit� un peu moins grande, car le robot se base
sur les champs d'en-t�te du message. Un utilisateur capable de bricoler son logiciel de messagerie pour y �crire une adresse de mod�rateur dans un champ
d'en-t�te pourrait ainsi envoyer un message court-circuitant la mod�ration.</p>

<p><font color="#800000"><b>privateoreditorkey :&nbsp;</b></font> Les messages post�s par les abonn�s sont diffus�s directement, comme avec le param�tre <i>p
rivate</i> seul. Les messages post�s par les non abonn�s sont soumis � la mod�ration dans les m�mes conditions qu'avec le param�tre <i>editorkey</i>.
</p>

<p><font color="#800000"><b>privateandeditor :&nbsp;</b></font> Ce mode de contribution combine les options <i>private</i> et <i>editorkeyonly</i>.
Seuls les messages post�s par les abonn�s sont envoy�s aux mod�rateurs. Les messages des non abonn�s sont automatiquement rejet�s.
</p>   

<p><font color="#800000"><b>newsletter :&nbsp;</b></font>
Seuls les messages des mod�rateurs sont accept�s. Tous les autres messages, m�me ceux des abonn�s, sont rejet�s. Bien entendu, ce mode ne convient pas pour
une liste de discussion. Il est utilis� pour des listes diffusant des bulletins d'informations. 
</p>

[ELSIF p->NAME=editor]

<p><b><font color="#800000">Les mod�rateurs </font></b>sont responsables de la mod�ration des messages. Si la liste est mod�r�e, les messages post�s sur la
liste seront d'abord adress�s aux mod�rateurs qui pourront autoriser ou non la diffusion. Cette interface vous permet de d�signer plusieurs mod�rateurs,
en �crivant leur adresse dans un des champs.<br>
<i><font color="#800000">Remarques importantes :</font><br>
- </i>Il ne suffit pas de d�signer un mod�rateur pour que la liste soit mod�r�e. Vous devez �galement r�gler la valeur du param�tre &quot;mode de
contribution&quot; en cons�quence (voir aide sur le mode de contribution).<br>
- Si une liste poss�de plusieurs mod�rateurs, le premier mod�rateur qui accepte ou rejette un message prend la d�cision pour les autres. Si aucun
mod�rateur ne prend de d�cision, les messages en attente de mod�ration sont effac�s au bout d'une semaine.</p>

[ELSIF p->NAME=topics]
  D�finit la ou les rubrique(s) de l'annuaire des listes dans lesquelles cette
  liste sera class�e.
[ELSIF p->NAME=host]
  Indique le nom de serveur pour cette liste. L'adresse de la liste sera alors
  nom_de_la_liste@host
[ELSIF p->NAME=lang]
  D�finit la langue principale en usage pour cette liste.
[ELSIF p->NAME=web_archive]
<p>Ce param�tre ne concerne que les listes dont les messages sont archiv�s. Il
ne d�termine que le mode de consultation des messages par l'interface web, et
non le mode d'archivage lui-m�me. En particulier, m�me si la consultation des
archives est totalement ferm�e, les messages continuent d'�tre archiv�s. Si
vous souhaitez interrompre l'archivage lui-m�me, vous devez
en faire la demande aupr�s des administrateurs.</P>
<p><font color="#800000"><b>public</b> : </font>les archives sont consultables par tous, abonn�s ou non. Les contributeurs doivent �videmment �tre
conscients de cette situation. L'acc�s aux archives se faisant par l'interm�diaire de la page de pr�sentation de la liste, le mode 
<font color="#800000">public</font>n'a de sens que si le param�tre visibilit� de la liste est en mode <font color="#800000">noconceal</font>
(voir l'aide sur le param�tre visibilit� pour plus de d�tails).</p>
<p><font color="#800000"><b>private </b>:<b> </b></font>les archives sont accessibles seulement aux abonn�s. Pour les consulter, il faut se connecter �
l'interface web des listes en fournissant son mot de passe.</p>
<p><font color="#800000"><b>owner </b>: </font>les archives sont accessibles seulement aux propri�taires de la liste.</p>
<p><font color="#800000"><b>listmaster </b>: </font>les archives sont accessibles seulement aux administrateurs du service de listes.</p>
<p><font color="#800000"><b>closed </b>: </font>les archives sont ferm�es � toute consultation.</p>
<p><font color="#800000">Remarque : </font>en temps normal, seuls les deux premiers modes pr�sentent un int�r�t. Les autres modes ne doivent �tre
utilis�s que pendant une r�organisation importante des archives, ou en cas d'urgence. Exemple : vous souhaitez supprimer un message que vous estimez
diffamatoire. Vous pourrez interdire la consultation des archives jusqu'au retrait du message litigieux.</p>

[ELSIF p->NAME=archive]
  D�finit qui aura le droit de se faire envoyer par e-mail les archives
  r�capitulatives des messages de la liste, ainsi que la p�riodicit� de groupage
  de ces archives.<br>
  Par exemple, si la p�riodicit� est "month", l'ensemble des messages pass�s
  sur la liste en un mois seront regroup�s dans un message d'archives
  unique, qui pourra �tre demand� par e-mail au serveur.<br>
  Si ce param�tre n'est pas d�fini, la liste n'aura aucune archive consultable
  par mail.
[ELSIF p->NAME=digest]
  D�finit quels jours de la semaine, et � quelle heure, seront r�alis�es les
  compilations de tous les messages r�cents pass�s sur la liste, pour �tre
  envoy�s aux abonn�s qui ont choisi de ne recevoir que la compilation de la
  liste, plut�t que les messages individuels.
  Evitez de choisir un horaire compris entre 23h et minuit.
[ELSIF p->NAME=available_user_options]
  D�finit quelles sont les options de r�ception disponibles pour cette
liste :<br>
  - digest : Ne recevoir que la compilation p�riodique de la liste.<br>
  - mail : Recevoir tous les mails individuels transmis par la liste.<br>
  - nomail : Ne RIEN recevoir du tout.<br>
  - notice : Etre uniquement inform� des sujets des messages qui passent sur la
    liste.<br>
  - summary : Recevoir p�riodiquement une compilation qui ne comprend que les
    sujets des messages, sans leur contenu.
[ELSIF p->NAME=default_user_options]
  D�finit quelle option de r�ception (voir available_user_options) sera affect�e par d�faut
  � un nouvel abonn� de cette liste.
[ELSIF p->NAME=reply_to]
<p>Ce mode d�termine le comportement du robot lorsqu'un abonn� utilise la fonction &quot;r�pondre&quot; de son logiciel de messagerie en r�ponse � un
message publi� sur la liste.&nbsp;</p>
<p><font color="#800000"><b>sender</b></font> : la r�ponse est envoy�e � l'auteur du message. C'est le mode par d�faut d�fini lors de la cr�ation de
la liste.</p>
<p><font color="#800000"><b>list</b></font> : la r�ponse est envoy�e � la liste. Elle sera donc diffus�e � tous les abonn�s (�ventuellement apr�s
mod�ration, suivant la configuration de la liste). Ce mode convient plut�t aux listes de type &quot;liste de discussion&quot;. Si un abonn� veut r�pondre �
l'auteur du message personnellement, il ne doit pas utiliser la fonction &quot;r�pondre&quot; de son logiciel de messagerie, mais �crire directement �
l'auteur du message.&nbsp; <br>
Une mauvaise utilisation du&nbsp; mode list peut entra�ner des situations embarrassantes, comme la publication d'un message personnel. Pr�venez donc vos
abonn�s du mode de r�ponse utilis� (dans la page de pr�sentation ou le message de bienvenue).</p>

[ELSIF p->NAME=forced_reply_to]
  M�me fonction que pour "reply-to", mais permet de "forcer" l'adresse de
  r�ponse, m�me si le message envoy� � la liste sp�cifiait une adresse de r�ponse
  diff�rente.<br>
  Si ce param�tre n'est pas d�fini, et que le message re�u sp�cifie une adresse
  de r�ponse, celle-ci sera alors honor�e.
[ELSIF p->NAME=bounce]
  Indique le taux d'abonn�s en erreur (adresses mail invalides) � partir duquel
  le propri�taire de la liste recevra une notification de "taux d'erreurs
  important" l'invitant � supprimer de sa liste les abonn�s en erreur.<br>
  Indique �galement le taux d'erreurs � partir duquel la distribution des
  messages de la liste sera automatiquement interrompue.
[ELSIF p->NAME=bouncers_level1]
  La gestion automatique des abonn�s en erreur permet d'associer des actions � des 
  cat�gories d'utilisateurs. Ces cat�gories d�pendent du SCORE de chaque abonn� en erreur.
  Le Niveau 1 est le plus bas niveau (action par defaut : notification des abonn�s en erreur).
  <BR><BR>
    <UL>
    <LI>rate (Default value: 45)<BR><BR>
     Ce param�tre definit la limite inf�rieure du  niveau 1. Il faut savoir, que 
     les utilisateurs sont not�s de 0 � 100. Par exemple, par d�faut le niveau 1 concerne
     les abonn�s en erreur dont le score est compris entre 45 et 80 <BR><BR>
     </LI>
     <LI>action (Default value: notify_bouncers)<BR><BR>
     Ce param�tre d�fini l'action automatique qui est effectu�e p�riodiquement sur les abonn�s 
     en erreur du niveau 1. La notification tente de pr�venir les abonn�s en erreur<BR><BR>
     </LI>
     <LI>Notification (Default value: owner)<BR><BR>
     Il est possible de pr�venir par email le propri�taire ou le Listmaster, des actions effectu�es, et
     des adresses concern�es.<BR><BR>
     </LI>
     </UL>    
[ELSIF p->NAME=bouncers_level2]
  La gestion automatique des abonn�s en erreur permet d'associer des actions � des 
  cat�gories d'utilisateurs. Ces cat�gories d�pendent du SCORE de chaque abonn� en erreur.
  Le Niveau 2 est le plus haut niveau. <BR><BR>
    <UL>
    <LI>rate (Default value: 80)<BR><BR>
     Ce param�tre definit la limite entre le niveau 2, et le niveau 1. Il faut savoir, que 
     les utilisateurs sont not�s de 0 � 100. Par exemple, par d�faut le niveau 2 concerne
     les abonn�s en erreur dont le score est compris entre 80 et 100 <BR><BR>
     </LI>
     <LI> action (Default value: remove_bouncers)<BR><BR>
     Ce param�tre d�fini l'action automatique qui est effectu�e p�riodiquement sur les abonn�s 
     en erreur du niveau 2.<BR><BR>
     </LI>
     <LI>Notification (Default value: owner)<BR><BR>
     Il est possible de pr�venir par email le propri�taire ou le Listmaster, des actions effectu�es, et
     des adresses concern�es.<BR><BR>
     </LI>
     </UL>    
[ELSIF p->NAME=custom_subject]
Ce texte facultatif est plac� en t�te du champ sujet de la liste. Il est d'usage de mettre le nom de la liste entre crochets pour faciliter aux abonn�s le classement de leur courrier. On peut remplacer les crochets et le nom&nbsp; par toute autre indication permettant d'identifier le message comme provenant de la liste. 
[ELSIF p->NAME=invite]
  D�finit qui a le droit de faire envoyer, par l'interm�diaire du serveur, un
  message standard d'invitation � s'abonner � cette liste, en utilisant par mail
  la commande "invite".
[ELSIF p->NAME=max_size]
  Ce param�tre d�termine la taille maximum
d'un message qu'on peut poster sur la liste. En cas de d�passement, le message
est retourn� � l'envoyeur.
[ELSIF p->NAME=remind]
  Indique qui a le droit de faire envoyer, par l'interm�diaire du serveur, un
  message standard de rappel des abonnements � cette liste, en utilisant par mail
  la commande "remind".
[ELSIF p->NAME=review]
<p>Ce param�tre d�termine le droit d'acc�s � la liste des abonn�s, c'est � dire le comportement du robot en r�ponse � la commande REView ou certains
aspects de la page de pr�sentation de la liste.</p>
<p><font color="#800000"><b>owner</b> </font>: Seul le propri�taire de la liste peut obtenir la liste des abonn�s, que les abonn�s soient sur la &quot;liste
rouge&quot; ou non. <i><font color="#800000">Ce mode est fortement recommand� </font></i>compte-tenu de la multiplication des &quot;spams&quot;, &quot;hoaks&quot; et autres plaisanteries sur internet.</p>
<p><font color="#800000"><b>private</b> </font>: La liste des abonn�s est accessible � tous les abonn�s, soit par la commande REV, soit par l'interface
web � condition que l'abonn� se connecte en donnant son mot de passe. Dans un cas comme dans l'autre, les adresses �lectroniques des abonn�s inscrits sur la
&quot;liste rouge&quot; restent masqu�es (voir mode d'emploi de sympa).
N'utilisez ce mode que si vous avez une bonne raison de le&nbsp; faire. Par exemple pour une liste de travail r�serv�e � des interlocuteurs dont
l'activit� n�cessite qu'ils connaissent l'adresse des autres colistiers. Cela implique aussi un mode d'abonnement <font color="#800000">closed</font>, ou �
la rigueur <font color="#800000">owner</font>. </p>

[ELSIF p->NAME=shared_doc]
  D�finit qui a le droit de consulter et de modifier les documents qui peuvent
  �tre mis en place dans un "espace partag�" correspondant � cette liste de
  diffusion.
[ELSIF p->NAME=status]
  Indique l'�tat actuel de cette liste :<br>
  - Open : Liste active<br>
  - Closed : Liste ferm�e<br>
  - Pending : Liste en attente d'approbation et d'installation par
    l'administrateur du serveur (listmaster).
[ELSIF p->NAME=anonymous_sender]
  Si on d�sire que les messages transmis sur la liste masquent l'adresse e-mail
  de l'auteur r�el du message (exp�diteur anonyme), il est possible d'indiquer
  ici une adresse e-mail. Tous les messages diffus�s sur cette liste indiqueront
  alors cette adresse e-mail comme "auteur" du message.
[ELSIF p->NAME=clean_delay_queuemod]
  Indique le d�lai (en jours) au del� duquel les messages en attente de
  mod�ration pour cette liste, mais qui n'auraient pas �t� trait�s (ni approuv�s,
  ni rejet�s) seront automatiquement supprim�s par le serveur.
[ELSIF p->NAME=custom_header]
  D�finit un header personnalis� suppl�mentaire qui sera ajout� � chaque
  message transmis sur cette liste.
[ELSIF p->NAME=footer_type]
  Indique la mani�re dont l'en-t�te et le pied-de-lettre standard de la liste sont ajout�s aux messages
  diffus�s sur cette liste :<br>
  - mime : Ces �l�ments seront ajout�s au message sous forme de parties MIME
    s�par�es. Si le message est au d�part de type multipart/alternative, ces
    �l�ments seront cependant ignor�s.<br>
  - append : Sympa ne cr�era pas de parties MIME, mais ajoutera directement les
    textes d'en-t�te et de pied-de-lettre au corps du message, uniquement si
    celui-ci est de type text/plain. Dans le cas contraire, rien ne sera ajout�.
[ELSIF p->NAME=priority]
  D�finit la priorit� de traitement de cette liste, de la plus haute (1) � la
  plus basse (9). Si la priorit� est "z", les messages pour cette liste resteront
  ind�finiment en attente.
[ELSIF p->NAME=serial]
  Num�ro de s�rie de la configuration (nombre de modifications).
[ELSE]
  Pas d'aide disponible pour ce param�tre
[ENDIF]

</DL>
[END]
	
