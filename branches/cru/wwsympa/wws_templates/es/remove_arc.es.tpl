[IF status = done]
<b>Operaci�n realizada con �xito</b>. El mensaje ser� borrado tan pronto como sea posible.
Esta tarea puede permanecer inactiva durante unos minutos, no olvide de hacer un "reload" de la p�gina en cuesti�n.
[ELSIF status = no_msgid]
<b>Imposible de encontrar el mensaje para borrar. Seguramente, el mensaje fue recibido sin el campo "Message-Id:" 
Contacte con el listmaster con la URL completa del mensaje en cuesti�n.</center>
[ELSIF status = not_found]
<b>Imposible de encontrar el mensaje para borrar.</b>
[ELSE]
<b>Error al intentar borrar este mensaje, contacte con el listmaster con la URL completa del mensaje en cuesti�n.</b>
[ENDIF]