From: [from]
To: [list->name] lista moder�torai <[list->name]-editor@[list->host]>
Subject: Enged�lyez�sre v�r� lev�l
Reply-To: [conf->email]@[conf->host]
Mime-version: 1.0
Content-Type: multipart/mixed; boundary="[boundary]"

--[boundary]
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

[IF method=md5]
A(z) [list->name] list�n a mell�klet megjelen�s�nek j�v�hagy�s�hoz haszn�ld a k�vetkez� parancsot:
mailto:[conf->email]@[conf->host]?subject=DISTRIBUTE%20[list->name]%20[modkey]
Vagy [conf->email]@[conf->host] c�mre k�ldj egy levelet a k�vetkez� t�rggyal:
DISTRIBUTE [list->name] [modkey]

Visszautas�t�shoz (ez t�rl�st jelent) haszn�ld a k�vetkez�t:
mailto:[conf->email]@[conf->host]?subject=REJECT%20[list->name]%20[modkey]
Vagy [conf->email]@[conf->host] c�mre k�ldj egy levelet a k�vetkez� t�rggyal:
REJECT [list->name] [modkey]
[ENDIF]

--[boundary]
Content-Type: message/rfc822
Content-Transfer-Encoding: 8bit
Content-Disposition: inline

[INCLUDE msg]

--[boundary]--
