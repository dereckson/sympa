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

[ELSE]
Subject: Your message has been rejected.

Your message for list [list->name]@[list->host]
as been rejected by [rejected_by] list editor.

(Subject of your mail : [subject]) 


Check [list->name] list usage :
[conf->wwsympa_url]/info/[list->name]

[ENDIF]

