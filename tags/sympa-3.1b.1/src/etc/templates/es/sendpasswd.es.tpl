From: [conf->sympa]
Reply-to: [conf->request]
To: [newuser->email]
Subject: Your WWSympa environment

[IF init_passwd]
  [IF action=subrequest]
Usted solicit� subscribirse a la lista de correo [list].

Para confirmar esta operaci�n, siga este enlace:
[base_url][path_cgi]/subscribe/[list]/[newuser->escaped_email]/[newuser->password]

o utilice esta contrase�a :

	Contrase�a : [newuser->password]

  [ELSIF action=sigrequest]
Usted solicit� anular su subscripci�n a la lista [list].

Para confirmar esta operaci�n, siga este enlace:
[base_url][path_cgi]/signoff/[list]/[newuser->escaped_email]/[newuser->password]

o utilice esta contrase�a :

	Contrase�a : [newuser->password]

  [ELSE]
Usted solicit� una cuenta en WWSympa.

Para escoger su contrase�a, rellene el siguiente formulario:
[base_url][path_cgi]/login/[newuser->escaped_email]/[newuser->password]

o utilice esta contrase�a :

	Contrase�a : [newuser->password]

  [ENDIF]
Escoja su contrase�a : [base_url][path_cgi]/choosepasswd/[newuser->escaped_email]/[newuser->password]
[ELSE]
Recordatorio de su contrase�a de WWSympa 

	Contrase�a : [newuser->password]

Cambiar su contrase�a : [base_url][path_cgi]/choosepasswd
[ENDIF]
Ayuda de WWSympa : [base_url][path_cgi]/help
