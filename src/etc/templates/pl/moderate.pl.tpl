From: [from]
To: Moderatorzy listy [list->name] <[list->name]-editor@[list->host]>
Subject: List�w do potwierdzenia
Mime-version: 1.0
Content-Type: multipart/mixed; boundary="[boundary]"

--[boundary]
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

[IF method=md5]
Aby rozes�a� za��czon� wiadomo�� na list� [list->name]:
mailto:[conf->email]@[conf->host]?subject=DISTRIBUTE%20[list->name]%20[modkey]
Lub wy�lij wiadomo�� do [conf->email]@[conf->host] z tematem :
DISTRIBUTE [list->name] [modkey]

Aby odrzuci� j� (zostanie usuni�ta):
mailto:[conf->email]@[conf->host]?subject=REJECT%20[list->name]%20[modkey]
Lub wy�lij wiadomo�� do [conf->email]@[conf->host] z tematem :
REJECT [list->name] [modkey]
[ENDIF]

--[boundary]
Content-Type: message/rfc822
Content-Transfer-Encoding: 8bit
Content-Disposition: inline

[INCLUDE msg]

--[boundary]--

