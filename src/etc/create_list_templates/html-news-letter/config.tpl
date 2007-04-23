subject [subject]

status [status]

topics [topics]

visibility noconceal

send editorkeyonly

available_user_options 
reception mail,nomail,txt,html

default_user_options 
reception html

web_archive
  access public

archive
  period year
  access owner

clean_delay_queuemod 15

subscribe open

unsubscribe open,notify

review owner

invite default

custom_subject [listname]

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


