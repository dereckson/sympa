<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF status = done]
<b>Operation successful</b>. The message will be deleted as soon
as possible. This task may be down in a few minutes, don't forget to
reload the incriminated page.
[ELSIF status = no_msgid]
<b>Unable to find the message to delete</b>, probably this message
was received without "Message-Id:" Please refer to listmaster with
complete URL of the incriminated message
[ELSIF status = not_found]
<b>Unable to find the message to delete</b>
[ELSE]
<b>Error while deleting this message</b>, please refer to listmaster with
complete URL of the incriminated message.
[ENDIF]