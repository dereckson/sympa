<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF status = done]
<b>Op�ration r�ussie</b>. Le message sera d�truit rapidement (quelques
minutes). N'oubliez pas de rafra�chir la page concern�e pour le v�rifier.
[ELSIF status = no_msgid]
<b>Impossible de trouver le message � d�truire</b>, probablement, ce
message a �t� re�u sans l'ent�te <code>Message-Id:</code>. Merci
de contacter le <i>listmaster</i> et de lui transmettre l'URL
du message � d�truire.
[ELSIF status = not_found]
<b>Impossible de trouver le message � d�truire</b>
[ELSE]
<b>Erreur lors de la suppression de ce message</b>; Merci
de contacter le <i>listmaster</i> et de lui transmettre l'URL
du message � d�truire.
[ENDIF]