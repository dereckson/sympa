subject [subject]

status [status]

[IF topics]
topics [topics]
[ENDIF]

visibility noconceal

send public

web_archive
  access private

archive
  period month
  access owner

clean_delay_queuemod 15

subscribe owner

unsubscribe open,notify

review private

invite default

custom_subject [listname]

digest 5 20:56

owner
  email [owner->email]
  profile privileged
  [IF owner->gecos] 
  gecos [owner->gecos]
  [ENDIF]

editor
  email [owner->email]

creation
  date [creation->date]
  date_epoch [creation->date_epoch]
  email [creation->email]

serial 0