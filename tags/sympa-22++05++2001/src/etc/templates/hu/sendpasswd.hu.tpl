Felad�: [conf->sympa]
Reply-to: [conf->request]
C�mzett: [newuser->email]
[IF action=subrequest]
T�rgy: [wwsconf->title] / subscribing to [list]
[ELSIF action=sigrequest]
T�rgy: [wwsconf->title] / unsubscribing from [list]
[ELSE]
T�rgy: [wwsconf->title] / your environment
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

