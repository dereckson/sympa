From: [conf->email]@[conf->host]
To: Listmaster <[to]>
[IF type=request_list_creation]
Subject: Listi "[list->name]" soov 

[email] soovis listi "[list->name]"

[list->name]@[list->host]
[list->subject]
[conf->wwsympa_url]/info/[list->name]

Listi loomiseks/kustutamiseks on j�rgnev URL:
[conf->wwsympa_url]/get_pending_lists
[ELSIF type=virus_scan_failed]
Subject: Viirusekontroll ei �nnestunud

Viirusekontroll katkes j�rgneva faili t��tlemise ajal: 
	[filename]

Veateade on:
	[error_msg]
[ELSIF type=edit_list_error]
Subject: Viga failis edit_list.conf

edit_list.conf fomaat on muutunud: 
 'default' v��rtus ei ole enam v�imalik

Vaadake dokumentatsiooni parameetri [param0] kohta.
Ajutiseks lahenduseks sobib parameetri [param0] eemaldamine,
sellisel juhul kasutatakse vaikimisi v��rtust.
[ENDIF]
