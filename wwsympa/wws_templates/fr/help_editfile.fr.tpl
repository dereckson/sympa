<!-- RCS Identication ; $Revision$ ; $Date$ -->

Description des messages de service :<UL>
<LI>Message de bienvenue : Ce message est envoy� aux nouveaux abonn�s.
Vous pouvez utiliser un message MIME structur� (r�serv� aux experts
du format MIME).

<LI>Message de d�sabonnement : Envoy� aux personnes qui se d�sabonnent de la liste.

<LI>Message de suppression : ce message est envoy� aux personnes, que vous d�sabonnez (commande DEL),&nbsp; notamment parce que leur adresse a g�n�r� des erreurs.

<LI>Message de rappel individualis� : ce message est envoy� aux
abonn�s lors d'un rappel individualis� (commande REMIND). La commande REMIND est importante pour la bonne gestion de votre liste, car de nombreuses erreurs d'acheminement du courrier (bounces) sont dues � des personnes dont l'adresse courante ne correspond plus � l'adresse d'abonnement, ou m�me qui ont oubli� leur abonnement. 


<LI>Invitation � s'abonner : Message envoy� � une personne via la commande
<CODE>INVITE [nom de liste]</CODE>.
</UL>

Description des autres fichiers/pages :<UL>

<LI>Description de la liste : ce texte d�crivant la liste est envoy� par m�l en r�ponse � la commande INFO. 
Il peut �galement �tre automatiquement  inclus dans le message de bienvenue. Il ne doit pas �tre confondu avec la page de pr�sentation de la liste qui est affich�e sur le site wws, et qui est �ditable � partir du lien <i>Editer la page de pr�sentation de la liste</i>. 

<LI>Page d'accueil de la liste : ce texte d�crivant la liste est pr�sent� dans la partie droite de la page d'info de la liste. Il peut �tre au format HTML. Si vous n'utilisez pas ce format, employez toutefois les balises BR pour marquer les sauts de ligne.
Par ailleurs, un texte de pr�sentation de la liste peut �tre envoy� par m�l � tout nouvel abonn�, ou en r�ponse � la commade INFO. Ce texte fait partie des 
messages de service modifiables

<LI>Description de la liste : Ce texte est envoy� en retour
� la commande <code>INFO [nom de liste]</code> en mode messagerie.
Il est aussi inclus dans le <I>message de bienvenue</I>.

<LI>Attachement de d�but de message : s'il est d�fini, une partie MIME comprenant le texte sera ajout�e au d�but de chaque message
diffus� dans la liste.

<LI>Attachement de fin de message : s'il est d�fini, une partie MIME comprenant le texte sera ajout�e en fin de chaque message
diffus� dans la liste.

</UL>

	


