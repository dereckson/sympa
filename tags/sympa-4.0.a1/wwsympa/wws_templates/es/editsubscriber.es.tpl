<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM ACTION="[path_cgi]" METHOD=POST>
<TABLE WIDTH="100%" BORDER=0>
<TR><TH BGCOLOR="[dark_color]">
<FONT COLOR="[bg_color]">Informaci�n del Suscriptor</FONT>
</TH></TR><TR><TD>
<INPUT TYPE="hidden" NAME="previous_action" VALUE=[previous_action]>
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<INPUT TYPE="hidden" NAME="email" VALUE="[subscriber->escaped_email]">
<DL>
<DD>Email : <A HREF="mailto:[subscriber->email]">[subscriber->email]</A>
<DD>Nombre : <INPUT NAME="gecos" VALUE="[subscriber->gecos]" SIZE="25">
<DD>Suscrito desde [subscriber->date]
<DD>Recepci�n : <SELECT NAME="reception">
		  [FOREACH r IN reception]
		    <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
		  [END]
	        </SELECT>

<DD>Visibilidad : [subscriber->visibility]
<DD>Idioma : [subscriber->lang]
<DD><INPUT TYPE="submit" NAME="action_set" VALUE="Actualizar">
<INPUT TYPE="submit" NAME="action_del" VALUE="Anular su suscripci�n">
<INPUT TYPE="checkbox" NAME="quiet"> silencioso
</DL>
</TD></TR>
[IF subscriber->bounce]
<TR><TH BGCOLOR="[error_color]">
<FONT COLOR="[bg_color]">Direcci�n err�nea</FONT>
</TD></TR><TR><TD>
<DL>
<DD>Estado : [subscriber->bounce_status] ([subscriber->bounce_code])
<DD>Nro. de errores: [subscriber->bounce_count]
<DD>Per�odo : from [subscriber->first_bounce] to [subscriber->last_bounce]
<DD><A HREF="[path_cgi]/viewbounce/[list]/[subscriber->escaped_email]">Ver �ltimo error</A>
<DD><INPUT TYPE="submit" NAME="action_resetbounce" VALUE="Inicializar errores">
</DL>
</TD></TR>
[ENDIF]
</TABLE>
</FORM>



