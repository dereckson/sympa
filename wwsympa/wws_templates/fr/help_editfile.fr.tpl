<!-- RCS Identication ; $Revision$ ; $Date$ -->

Description des messages de service :<UL>
<LI>Message de bienvenue : Ce message est envoy� aux nouveaux abonn�s.
Vous pouvez utiliser un message MIME structur� (r�serv� aux experts
du format MIME).

<LI>Message de d�sabonnement : Envoy� aux personnes qui se d�sabonnent de la liste.

<LI>Message de suppression : Envoy� aux personnes supprim�s de la liste des abonn�s
par le propri�taire de la liste ou via le module de gestion des erreurs.

<LI>Message de rappel individualis� : Message envoy� � chaque abonn� lors du rappel des abonnements. Ce message peut �tre envoy� depuis l'interface d'administration de liste dans la page <i>abonn�s</i>. Cette proc�dure est tr�s utile
pour aider chaque personne � se d�sabonner au cas o� celles-ci
ne connaissent plus leur adresse d'abonnement.

<LI>Invitation � s'abonner : Message envoy� � une personne via la commande
<CODE>INVITE [nom de liste]</CODE>.

Description des autres fichiers/pages :<UL>
<LI>Page d'accueil de la liste : Description de la liste  au format HTML. S'affiche en partie droite de la page de la liste. (a pour d�faut la description de la liste)

<LI>Description de la liste : Ce texte est envoy� en retour
� la commande <code>INFO [nom de liste]</code> en mode messagerie.
Il est aussi inclus dans le <I>message de bienvenue</I>.

<LI> Attachement de d�but de message : Si non vide, ce fichier est
attach� au d�but de chaque message diffus� dans la liste.
<LI> Attachement de fin de message : Identique � l'<i>Attachement de d�but de message</i> mais attach� en fin de message.


</UL>

	


