From: [conf->sympa]
Reply-to: [conf->request]
To: [newuser->email]
[IF action=subrequest]
Subject: [conf->title] / feliratkoz�s a(z) [list] list�ra
[ELSIF action=sigrequest]
Subject: [conf->title] / leiratkoz�s a(z) [list] list�r�l
[ELSE]
Subject: [conf->title] / be�ll�t�said
[ENDIF]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

[IF action=subrequest]
Ha t�nyleg fel szeretn�l iratkozni a(z) [list] levelez�list�ra,
akkor a k�relmedet a k�vetkez� jelsz�val meg kell er�s�tened:

	jelsz�: [newuser->password]

[ELSIF action=sigrequest]
Ha t�nyleg t�r�lni szeretn�d magadat a(z) [list] levelez�list�r�l,
akkor azt a k�vetkez� jelsz�val meg kell er�s�tened:

	jelsz�: [newuser->password]

[ELSE]
Be�ll�t�said megtekint�s�hez el�sz�r is be kell l�pned

     e-mail c�med: [newuser->email]
     jelszavad   : [newuser->password]

A jelszavadat az al�bbi c�men tudod megv�ltoztatni 
[base_url][path_cgi]/choosepasswd/[newuser->escaped_email]/[newuser->password]
[ENDIF]


[conf->title]: [base_url][path_cgi] 

S�g� a Sympa haszn�lat�hoz: [base_url][path_cgi]/help
