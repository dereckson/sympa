subject [subject]

status [status]

topics [topics]

visibility noconceal

send privateorpublickey

web_archive
  access intranet

archive
  period month
  access owner

clean_delay_queuemod 15

reply_to sender

subscribe intranet

unsubscribe open,notify

review private

invite default

custom_subject [listname]

digest 1,4 6:56

owner
  email [owner->email]
  profile privileged
  [IF owner->gecos] 
  gecos [owner->gecos]
  [ENDIF]

editor
  email [owner->email]

creation
  date [date]
  date_epoch [date_epoch]
  email [owner->email]

serial 0