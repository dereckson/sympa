
              SYMPA -- Syst�me de Multi-Postage Automatique
 
                       Guide de l'utilisateur


SYMPA est un gestionnaire de listes �lectroniques. Il permet d'automatiser
les fonctions de gestion des listes telles que les abonnements, la mod�ration
et la gestion des archives.

Toutes les commandes doivent �tre adress�es � l'adresse �lectronique
[conf->sympa].

Il est possible de mettre plusieurs commandes dans chaque message :
les commandes doivent appara�tre dans le corps du message et chaque ligne ne
doit contenir qu'une seule commande. Sympa ignore le corps du message
si celui-ci n'est pas de type "Content-type: text/plain", mais m�me si vous
�tes fanatique d'un agent de messagerie qui fabrique syst�matiquement des
messages "multipart" ou "text/html", les commandes plac�es dans le sujet
du messages sont reconnues.

Les commandes disponibles sont :

 HELp                        * Recevoir ce fichier d'aide
 LISts                       * Recevoir l'annuaire des listes g�r�es sur ce
                               noeud
 REView <list>               * Recevoir la liste des abonn�s � <list>
 WHICH                       * Recevoir la liste des listes auxquelles
                               on est abonn�
 SUBscribe <list> Pr�nom Nom * S'abonner ou confirmer son abonnement � <list>
 SIGnoff <list|*> [user->email]    * Quitter <list>, ou toutes les listes
                               ([user->email] est facultatif)

 SET <list|*> NOMAIL         * Suspendre la r�ception des messages de <list>
 SET <list|*> MAIL           * Recevoir les messages en mode normal
 SET <list|*> DIGEST         * Recevoir une compilation des messages
 SET <list|*> DIGESTPLAIN    * Recevoir une compilation des messages, en mode texte,
	                       sans les attachements
 SET <list|*> SUMMARY        * Recevoir la liste des messages uniquement
 SET <list|*> NOTICE         * Recevoir l'objet des message uniquement

 SET <list|*> CONCEAL        * Passage en liste rouge (adresse d'abonn� cach�e)
 SET <list|*> NOCONCEAL      * Adresse d'abonn� visible via REView

 INFO <list>                 * Recevoir les informations sur <list>
 INDex <list>                * Recevoir la liste des fichiers de l'archive
                               de <list>
 GET <list> <fichier>        * Recevoir <fichier> de l'archive de <list>
 LAST <list>                 * Recevoir le dernier message de <list>
 INVITE <list> <e-mail>      * Inviter <e-mail> � s'abonner � <list>
 CONFIRM <clef>              * Confirmer l'envoi d'un message
                               (selon la configuration de la liste)
 QUIT                        * Indiquer la fin des commandes
                               (pour ignorer une signature)

[IF is_owner]
Commandes r�serv�es aux propri�taires de listes :
 
 ADD <list> user@host Prenom Nom * Ajouter un utilisateur � <list>
 DEL <list> user@host            * Supprimer un utilisateur de <list>
 STATS <list>                    * Consulter les statistiques de <list>
 EXPire <list> <ancien> <delai>  * D�clancher un processus d'expiration pour
                                   les abonn�s � <list> n'ayant pas confirm�
                                   leur abonnement depuis <ancien> jours.
                                   Les abonn�s ont <delai> jours pour
                                   confirmer
 EXPireINDex <list>              * Conna�tre l'�tat du processus d'expiration
                                   en cours pour la liste <list>
 EXPireDEL <list>                * D�sactiver le processus d'expiration de
                                   <list>

 REMind <list>                   * Envoyer � chaque abonn� un message
                                   personnalis� lui rappelant l'adresse
                                   avec laquelle il est abonn�
[ENDIF]

[IF is_editor]

Commandes r�serv�es aux mod�rateurs de listes :

 DISTribute <list> <clef>        * Mod�ration : valider un message
 REJect <list> <clef>            * Mod�ration : invalider un message
 MODINDEX <list>                 * Mod�ration : consulter la liste des messages
                                                � mod�rer
[ENDIF]

Powered by Sympa [conf->version] : http://listes.cru.fr/sympa/
