<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH p IN param]
<A NAME="[p->NAME]">
<B>[p->title]</B> ([p->NAME]) :
<DL>
<DD>
[IF p->NAME=subject]
  Sujet de la liste tel qu'il appara�tra dans l'annuaire des listes
[ELSIF p->NAME=visibility]
  D�finit si la liste sera visible pour tous, ou si sa visibilit� sera
  restreinte.
[ELSIF p->NAME=info]
  Indique qui peut consulter la page d'information (page d'accueil) de la
  liste.
[ELSIF p->NAME=subscribe]
  D�finit les conditions requises pour s'abonner � cette liste. Principalement,
  l'abonnement peut �tre ouvert � tous (libre) ou soumis � autorisation du
  propri�taire de la liste.<br>
  Il est conseill� de toujours choisir une option comportant le param�tre "auth",
  car ainsi le syst�me demandera confirmation par mail au futur abonn� avant de l'abonner
  � la liste. Ceci permet � la fois d'�viter des prises d'abonnement avec une
  adresse e-mail invalide, et assure que personne ne peut �tre abonn� � la liste
  contre son gr� (par un tiers).
  Si l'option comporte le param�tre "notify", le propri�taire de la liste sera
  averti par mail pour chaque nouvel abonnement.
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
  D�finit le ou les propri�taires de la liste.
[ELSIF p->NAME=send]
  D�finit qui peut envoyer des messages � la liste.<br>
  Dans la plupart des cas, le droit de poster dans une liste est :<br>
  - soit r�serv� aux abonn�s de cette liste, sans mod�ration, et c'est alors le
    param�tre "private" qui s'applique.<br>
  - soit soumis � l'approbation du message par les mod�rateurs de la
    liste, et c'est alors les param�tres "editor", "editorkey" ou
    "editorkeyonly" qui s'appliquent.<br>
  - soit la liste est de type "lettre d'information" issue uniquement des
    mod�rateurs, et il faut alors utiliser "newsletter",
    "newsletterkey" ou "newsletterkeyonly".<br>
  Les modes d'approbation diff�rent selon la s�curit� qu'ils apportent :<br>
  - editor ou editorkey : Un message provenant (from) du mod�rateur sera diffus� directement.
    Un message ne provenant pas du mod�rateur sera transmis � celui-ci pour
    approbation. Cependant, l'authenticit� de la provenance n'est pas v�rifi�e,
    aussi, une forme de falsification est possible.<br>
  - editorkeyonly : Tout message devra �tre confirm� par le mod�rateur (au moyen
    d'une cl� de contr�le qui lui sera envoy�e par le serveur), MEME si ce
    message semble provenir directement du mod�rateur lui-m�me. Ceci limite tr�s
    fortement les possibilit�s de fraude dans la diffusion de messages, mais rend
    le processus de mod�ration plus lourd.
[ELSIF p->NAME=editor]
  D�finit qui sont le ou les "mod�rateurs" de la liste, si celle-ci est
  "mod�r�e". Les mod�rateurs ont la charge d'approuver chaque message avant sa
  diffusion sur la liste.<br>
  Par d�faut, le mod�rateur est le propri�taire de la liste, m�me si celle-ci n'a
  pas �t� d�finie comme mod�r�e.<br>
  Pour que la mod�ration soit active, il faut d�finir ce comportement dans le
  param�tre "send" (Qui peut diffuser des messages).<br>
  Astuce : Si la liste n'est pas mod�r�e, et que l'on ne souhaite pas afficher de
  nom ou d'adresse e-mail de mod�rateur sur la page "Info" de la liste, il est
  possible d'indiquer "Liste non mod�r�e" par exemple, � la place du nom du
  premier mod�rateur.
[ELSIF p->NAME=topics]
  D�finit la ou les rubrique(s) de l'annuaire des listes dans lesquelles cette
  liste sera class�e.
[ELSIF p->NAME=host]
  Indique le nom de serveur pour cette liste. L'adresse de la liste sera alors
  nom_de_la_liste@host
[ELSIF p->NAME=lang]
  D�finit la langue principale en usage pour cette liste.
[ELSIF p->NAME=web_archive]
  D�finit qui aura le droit de consulter les messages de la liste en utilisant
  l'interface web du serveur.<br>
  Si ce param�tre n'est pas d�fini, aucune archive web ne sera cr��e.
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
  D�finit ce qui se passe par d�faut quand un abonn� utilise le bouton
  "r�pondre" sur un message provenant de la liste :<br>
  - list : La r�ponse est adress�e � la liste.<br>
  - sender : La r�ponse est adress�e � l'auteur du message original.
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
[ELSIF p->NAME=custom_subject]
  D�finit un sujet fixe qui appara�tra entre crochets pour chaque message
  transmis par la liste, afin d'en faciliter le classement.<br>
  Il est d'usage d'indiquer ici le nom de la liste, ou son abr�viation.<br>
  Ne pas mettre les crochets, qui seront ajout�s automatiquement par le syst�me.
[ELSIF p->NAME=invite]
  D�finit qui a le droit de faire envoyer, par l'interm�diaire du serveur, un
  message standard d'invitation � s'abonner � cette liste, en utilisant par mail
  la commande "invite".
[ELSIF p->NAME=max_size]
  Indique la taille maximale des messages qui seront accept�s sur cette liste.
  Les messages plus gros seront rejet�s.
[ELSIF p->NAME=remind]
  Indique qui a le droit de faire envoyer, par l'interm�diaire du serveur, un
  message standard de rappel des abonnements � cette liste, en utilisant par mail
  la commande "remind".
[ELSIF p->NAME=review]
  Indique qui a le droit de consulter la liste des abonn�s de cette liste de
  diffusion.
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
	
