<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM ACTION="[path_cgi]" METHOD=POST>
<TABLE WIDTH="100%" BORDER=0>
<TR><TH BGCOLOR="--DARK_COLOR--">
<FONT COLOR="--BG_COLOR--">Inform�ci�k a listatagokr�l</FONT>
</TH></TR><TR><TD>
<INPUT TYPE="hidden" NAME="previous_action" VALUE=[previous_action]>
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<INPUT TYPE="hidden" NAME="email" VALUE="[subscriber->escaped_email]">
<DL>
<DD>Email: <INPUT NAME="new_email" VALUE="[subscriber->email]" SIZE="25">
<DD>N�v: <INPUT NAME="gecos" VALUE="[subscriber->gecos]" SIZE="25">
<DD>[subscriber->date] �ta listatag
<DD>K�ld�si m�d: <SELECT NAME="reception">
		  [FOREACH r IN reception]
		    <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
		  [END]
	        </SELECT>

<DD>Nyilv�noss�g: [subscriber->visibility]
<DD>Nyelv: [subscriber->lang]
<DD><INPUT TYPE="submit" NAME="action_set" VALUE="Friss�t">
<INPUT TYPE="submit" NAME="action_del" VALUE="A tag t�rl�se">
<INPUT TYPE="checkbox" NAME="quiet"> nincs �rtes�t�s
</DL>
</TD></TR>
[IF subscriber->bounce]
<TR><TH BGCOLOR="--ERROR_COLOR--">
<FONT COLOR="--BG_COLOR--">Visszapattan� c�mek</FONT>
</TD></TR><TR><TD>
<DL>
<DD>�llapot: [subscriber->bounce_status] ([subscriber->bounce_code])
<DD>Visszak�ld�sek: [subscriber->bounce_count]
<DD>Id�szak: [subscriber->first_bounce]-t�l/t�l [subscriber->last_bounce]-ig
<DD><A HREF="[path_cgi]/viewbounce/[list]/[subscriber->escaped_email]">Mutasd az utols�t</A>
<DD><INPUT TYPE="submit" NAME="action_resetbounce" VALUE="Hib�k t�rl�se">
</DL>
</TD></TR>
[ENDIF]
</TABLE>
</FORM>



