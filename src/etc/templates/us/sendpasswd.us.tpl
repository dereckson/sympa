<!-- RCS Identication ; $Revision$ ; $Date$ -->

From: [conf->sympa]
Reply-to: [conf->request]
To: [newuser->email]
Subject: Your [wwsconf->title] environment

[IF action=subrequest]
You requested a subscription to [list] mailing list.

To confirm your subscription, you need to provide the following password

	password: [newuser->password]

[ELSIF action=sigrequest]
You requested unsubscription from [list] mailing list.

To unsubscribe from the list, you need to provide the following password

	password: [newuser->password]

[ELSE]
To access your personal environment, you need to login first

     your email address    : [newuser->email]
     your password : [newuser->password]

Changing your password 
[base_url][path_cgi]/choosepasswd/[newuser->escaped_email]/[newuser->password]
[ENDIF]


[wwsconf->title]: [base_url][path_cgi] 

Help on Sympa: [base_url][path_cgi]/help

