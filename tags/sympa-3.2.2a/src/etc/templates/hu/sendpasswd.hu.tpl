From: [conf->sympa]
Reply-to: [conf->request]
To: [newuser->email]
[IF action=subrequest]
Subject: [wwsconf->title] / feliratkoz�s a(z) [list] list�ra
[ELSIF action=sigrequest]
Subject: [wwsconf->title] / leiratkoz�s a(z) [list] list�r�l
[ELSE]
Subject: [wwsconf->title] / be�ll�t�said
[ENDIF]

[IF action=subrequest]
Feliratkoz�sodat k�rted a(z) [list] levelez�list�ra.

Feliratkoz�sodat a k�vetkez� jelsz�val er�s�theted meg.

	jelsz�: [newuser->password]

[ELSIF action=sigrequest]
Leiratkoz�sodat k�rted a(z) [list] levelez�list�r�l.

Leiratkoz�sodat a k�vetkez� jelsz�val er�s�theted meg.

	jelsz�: [newuser->password]

[ELSE]
Egy�ni be�ll�t�said megtekint�s�hez be kell jelentkezned

     email c�med  : [newuser->email]
     jelszavad    : [newuser->password]

Jelszavadat itt v�ltoztathatod meg
[base_url][path_cgi]/choosepasswd/[newuser->escaped_email]/[newuser->password]
[ENDIF]


[wwsconf->title]: [base_url][path_cgi] 

S�g� a Sympa haszn�lat�hoz: [base_url][path_cgi]/help

