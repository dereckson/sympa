From: [conf->email]@[conf->host]
[IF  list->lang=fr]
Subject: Rejet de votre message
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

Votre message pour la liste [list->name]@[list->host]
a �t� rejet� par [rejected_by], moderateur de la liste.

L'objet de votre message : [subject]


V�rifiez les conditions d'utilisation de cette liste :
[conf->wwsympa_url]/info/[list->name]

[ELSIF list->lang=es]
Subject: Rechazo de su mensaje
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

Su mensaje a la lista [list->name]@[list->host]
ha sido rechazado por [rejected_by], moderador de la lista.

El tema de su mensaje era : [subject]

Verifique las normas de uso de la lista:
[conf->wwsympa_url]/info/[list->name]

[ELSIF list->lang=pl]
Subject: Twoja wiadomo�� nie zosta�a rozes�ana
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

Twoja wiadomo�� wy�ana na list� [list->name]@[list->host]
nie zosta�a rozes�ana. Odrzuci� j� moderator listy: [rejected_by]

Temat Twojego listu : [subject]

Verifique las normas de uso de la lista:
[conf->wwsympa_url]/info/[list->name]
[ELSIF list->lang=cz]
Subject: Vase zprava byla odmitnuta
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

Va�e zpr�va do konference [list->name]@[list->host]
nebyla rozesl�na. Byla odm�tnuta moder�torem konference:
[rejected_by]

Subjekt Va�� zpr�vy: [subject]

Zkontrolujte podm�nky pro u��v�n� konference:
[conf->wwsympa_url]/info/[list->name]

[ELSIF list->lang=de]
Subject: Ihr Beitrag wurde abgelehnt.
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

Ihr Beitrag zur Mailing-Liste [list->name]@[list->host]
wurde von [rejected_by] (Moderator) abgelehnt.

(Titel Ihrer EMail: [subject])


Sie k�nnen genaueres �ber die Liste erfahren unter:
[conf->wwsympa_url]/info/[list->name]

[ELSIF list->lang=hu]
Subject: A leveled nem jelenhet meg
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

A(z) [list->name]@[list->host] list�ra k�ld�tt
leveled megjelen�s�t [rejected_by] moder�tor elutas�totta.

(Eredeti level t�rgya: [subject])

[list->name] lista haszn�lat�r�l b�vebben itt olvashatsz:
[conf->wwsympa_url]/info/[list->name]

[ELSIF list->lang=pt]
Subject: Recha�o da sua mensagem
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

Sua mensagem para a lista [list->name]@[list->host]
foi recha�ado por [rejected_by], moderador da lista.

O tema da sua mensagem era : [subject]

Verifique as normas de uso da lista:
[conf->wwsympa_url]/info/[list->name]

[ELSE]
Subject: Your message has been rejected.

Your message for list [list->name]@[list->host]
as been rejected by [rejected_by] list editor.

(Subject of your mail : [subject]) 


Check [list->name] list usage :
[conf->wwsympa_url]/info/[list->name]

[ENDIF]

