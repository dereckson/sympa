<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM ACTION="[path_cgi]" METHOD="POST">
De : [user->email]<BR>
A : [mailto]<BR>
Objet : <INPUT TYPE="text" SIZE ="45" NAME="subject" VALUE="[subject]">
<INPUT TYPE="submit" NAME="action_send_mail" VALUE="Envoyer le message">
<BR>
<INPUT TYPE="hidden" NAME="in_reply_to" value="[in_reply_to]">
<INPUT TYPE="hidden" NAME="message_id" value="[message_id]">
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<INPUT TYPE="hidden" NAME="to" VALUE="[local_to] [domain_to]">

<TEXTAREA NAME="body" COLS=80 ROWS=25>
</TEXTAREA>

</FORM>
