From: [conf->sympa]
Reply-to: [conf->request]
To: [newuser->email]
[IF action=subrequest]
Subject: [conf->title] / abonnement � [list]
[ELSIF action=sigrequest]
Subject: [conf->title] / d�sabonnement de [list]
[ELSE]
Subject: [conf->title] / votre environnement
[ENDIF]

[IF action=subrequest]
Vous avez demand� � vous abonner � la liste [list].

Pour valider votre abonnement, vous devez fournir le mot de passe suivant :

	[newuser->password]

[ELSIF action=sigrequest]
Vous avez demand� � vous d�sabonner de la liste [list].

Pour vous d�sabonner, vous devez fournir le mot de passe suivant :
	
	[newuser->password]

[ELSE]
Pour personnaliser votre environnement, vous devez vous identifier:

     votre adresse �lectronique : [newuser->email]
     votre mot de passe         : [newuser->password]

Pour modifier votre mot de passe :
[base_url][path_cgi]/choosepasswd/[newuser->escaped_email]/[newuser->password]
[ENDIF]

[conf->title] : [base_url][path_cgi] 

Aide sur Sympa : [base_url][path_cgi]/help
