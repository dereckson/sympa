From: [conf->sympa]
Reply-to: [conf->request]
To: [newuser->email]
[IF action=subrequest]
Subject: [conf->title] / prihlaseni se do konference [list]
[ELSIF action=sigrequest]
Subject: [conf->title] / odhlaseni se z konference [list]
[ELSE]
Subject: [conf->title] / vase prostredi
[ENDIF]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

[IF action=subrequest]
Po�adoval jste p�ihl�en� se do konference [list].

Pro potvrzen� Va�eho p�ihl�en�, mus�te poskytnout n�sleduj�c� heslo

	heslo: [newuser->password]

[ELSIF action=sigrequest]
Po�adoval jste odhl�en� se do konference [list].

Pro potvrzen� Va�eho odhl�en�, mus�te poskytnout n�sleduj�c� heslo

	heslo: [newuser->password]

[ELSE]
Pro p��stup k Va�emu osobn�mu prostred� se mus�te nejprve p�ihl�sit

     Va�e adresa  : [newuser->email]
     Va�e heslo   : [newuser->password]

Pro zm�nu Va�eho hesla:
[base_url][path_cgi]/choosepasswd/[newuser->escaped_email]/[newuser->password]
[ENDIF]

[conf->title]: [base_url][path_cgi] 

N�pov�da pro syst�m Sympa: [base_url][path_cgi]/help
