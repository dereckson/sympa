From: [conf->sympa]
Reply-to: [conf->request]
To: [newuser->email]
Subject: Votre environnement [wwsconf->title]

[IF action=subrequest]
Vous avez demand� � vous abonner � la liste de diffusion [list].

Pour valider votre abonnement, vous devez fournir le mot de passe suivant

	mot de passe : [newuser->password]

[ELSIF action=sigrequest]
Vous avez demand� � vous d�sabonner de la liste de diffusion [list].

Pour vous d�sabonner, vous devez fournir le mot de passe suivant
	
	mot de passe : [newuser->password]

[ELSE]
Pour personnaliser votre environnement, vous devez vous identifier (login)

     votre adresse �lectronique : [newuser->email]
     votre mot de passe         : [newuser->password]

Changement de mot de passe
[base_url][path_cgi]/choosepasswd/[newuser->escaped_email]/[newuser->password]
[ENDIF]

[wwsconf->title] : [base_url][path_cgi] 

Aide sur Sympa : [base_url][path_cgi]/help
