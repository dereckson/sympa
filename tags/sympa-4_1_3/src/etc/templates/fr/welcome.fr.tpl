From: [conf->email]@[conf->host]
Subject: Bienvenue sur la liste [list->name]
Mime-version: 1.0
Content-Type: multipart/alternative; boundary="===Sympa==="

--===Sympa===
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

Bienvenue dans la liste [list->name]

[INCLUDE 'info']

Votre adresse d'abonnement est : [user->email]

Pour envoyer un message diffus� � tous les abonn�s, �crivez � la liste elle-m�me :
    [list->name]@[list->host]

Pour toutes les commandes concernant votre abonnement, n'�crivez pas � la liste, mais � :
    [conf->sympa]

Pour avoir la liste des commandes disponibles, postez un m�l � l'adresse ci-dessus en �crivant HELP dans le sujet ou le corps du message.

Vous pouvez aussi utiliser une interface web en vous rendant � :
    [conf->wwsympa_url]/info/[list->name]

[IF user->password]
Votre mot de passe pour les commandes par web est : [user->password]
[ENDIF]

   ---

Si vous voulez vous d�sabonner de cette liste, envoyez simplement un mel vide � :
    [list->name]-unsubscribe@[list->host] 

ou bien utilisez l'interface web (bouton d�sabonnement).

--===Sympa===
Content-Type: text/html; charset=iso-8859-1
Content-transfer-encoding: 8bit

<HTML>
<HEAD>
<TITLE>Bienvenue dans la liste [list->name]@[list->host]</title>
<BODY  BGCOLOR=#ffffff>

Bienvenue sur la liste [list->name]
<br><br>
<PRE>
[INCLUDE 'info']
</PRE>
<br><br> 
Votre adresse d'abonnement est : [user->email] 
<br><br>
Pour envoyer un message diffus� � tous les abonn�s, �crivez � la liste elle-m�me :<br>
    mailto:[list->name]@[list->host]
<br><br>
Pour toutes les commandes concernant votre abonnement, n'�crivez pas � la liste, mais � :<br>
    mailto:[conf->sympa]
<br><br>
Pour avoir la liste des commandes disponibles, postez un m�l � l'adresse ci-dessus en �crivant HELP dans le sujet ou le corps du message.
<br><br>
Vous pouvez aussi utiliser une interface web en vous rendant � :
    [conf->wwsympa_url]/info/[list->name]        
<br><br>       
[IF user->password]<br> 
Votre mot de passe pour les commandes par web est : [user->password]
[ENDIF]   
<br>
   ---
<br>
Si vous voulez vous d�sabonner de cette liste, envoyez simplement un mel vide � :<br>
    mailto:[list->name]-unsubscribe@[list->host]                         
<br><br>
ou bien utilisez l'interface web (bouton d�sabonnement).

</BODY></HTML>
--===Sympa===--
