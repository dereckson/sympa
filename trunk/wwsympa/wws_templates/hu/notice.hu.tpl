[FOREACH notice IN notices]

[IF notice->msg=sent_to_owner]
K�r�sed a lista adminisztr�tor�hoz lett tov�bb�tva.

[ELSIF notice->msg=add_performed]
[notice->total] tag fel�rva

[ELSIF notice->msg=performed]
[notice->action] : v�ltoztat�sok sikeresen elmentve

[ELSIF notice->msg=list_config_updated]
A be�ll�t�sokat tartalmaz� �llom�ny friss�tve.

[ELSIF notice->msg=upload_success] 
[notice->path] �llom�ny sikeresen bet�ltve!

[ELSIF notice->msg=save_success] 
[notice->path] �llom�ny elmentve.

[ELSIF notice->msg=password_sent]
Jelszavad emailben el lett k�ldve.

[ELSIF notice->msg=you_should_choose_a_password]
Jelszavad m�dos�t�s�hoz v�laszd a fels� men� 'Be�ll�t�saim' r�sz�t.

[ELSE]
[notice->msg]

[ENDIF]

<BR>
[END]




