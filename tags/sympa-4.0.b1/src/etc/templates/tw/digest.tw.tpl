From: [from]
To: [to]
Reply-to: [reply]
Subject: �l�H�M�� [list->name] ���K�n(digest)
Mime-version: 1.0
Content-Type: multipart/mixed; boundary="[boundary1]"

--[boundary1]
Content-Type: text/plain; charset=cn-big5
Content-transfer-encoding: 8bit

�ؿ�:

[FOREACH m IN msg_list]
[m->id]. [m->subject] - [m->from]
[END]

--[boundary1]
Content-type: multipart/digest; boundary="[boundary2]"
Mime-Version: 1.0

This is a multi-part message in MIME format...

[FOREACH m IN msg_list]
--[boundary2]
Content-Type: message/rfc822
Content-Disposition: inline

[m->full_msg]

[END]
--[boundary2]
Content-Type: text/plain; charset=cn-big5
Content-transfer-encoding: 8bit
Content-Disposition: inline

�l�H�M�� [list->name] ������ - [date]

--[boundary2]--

--[boundary1]--



