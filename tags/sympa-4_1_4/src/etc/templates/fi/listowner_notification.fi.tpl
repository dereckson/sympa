From: [conf->email]@[conf->host]
To: Listowners <[to]>
[IF type=arc_quota_exceeded]
Subject: Listan "[list->name]" arkisto ylitt�nyt quota rajan

[list->name]@[list->host] arkiston on ylitt�nyt quota rajan. Arkiston
[list->name]@[list->host] k�ytt�m� koko on [size] tavua. Viestej� 
ei en�� tallenneta WWW-arkistoon. Ota yhteytt� listmaster@[conf->host]. 

[ELSIF type=arc_quota_95]
Subject: Lista "[list->name]" varoitus : arkisto [rate]% t�ynn�

[rate2]
[list->name]@[list->host] k�ytt�� [rate]% sallitusta quotasta.
Arkiston [list->name]@[list->host] k�ytt�m� koko on [size] tavua.

Viestit tallennetaan yh� arkistoon, mutta sinun tulisi ottaa 
yhteytt� listmaster@[conf->host]. 
[ENDIF]
