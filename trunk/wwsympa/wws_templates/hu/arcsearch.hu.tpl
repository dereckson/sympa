<!-- RCS Identication ; $Revision$ ; $Date$ -->

<H2>Tal�latok az arch�vumban 
<A HREF="[path_cgi]/arc/[list]/[archive_name]"><FONT COLOR="--DARK_COLOR--">[list]</font></a> : </H2>

<P>Keresend� kifejez�s: 
[FOREACH u IN directories]
<A HREF="[path_cgi]/arc/[list]/[u]"><FONT COLOR="--DARK_COLOR--">[u]</font></a> - 
[END]
</P>

A keres�sben megadott felt�telek <b> &quot;[key_word]&quot;</b> 
<I>

[IF how=phrase]
	(Ez a kifejez�s, 
[ELSIF how=any]
	(Az �sszes megadott sz�, 
[ELSE]
	(A szavak b�rmelyike, 
[ENDIF]

<i>

[IF case]
	kis- �s nagybet� nem k�l�nb�zik 
[ELSE]
	kis- �s nagybet� megk�l�nb�ztet�se 
[ENDIF]

[IF match]
	�s ha b�rmelyik sz�ban megtal�lhat�.)</i>
[ELSE]
	�s csak ha ez a teljes sz�.)</i>
[ENDIF]
<p>

<HR>

[IF age]
	<B>�jabb �zenetek el�l</b><P>
[ELSE]
	<B>R�gebbi �zenetek el�l</b><P>
[ENDIF]

[FOREACH u IN res]
	<DT><A HREF=[u->file]>[u->subj]</A> -- <EM>[u->date]</EM><DD>[u->from]<PRE>[u->body_string]</PRE>
[END]

<DL>
<B>Tal�latok</b>
<DT><B>[searched] tal�latb�l [num] mutatva...</b><BR>

[IF body]
	<DD><B>[body_count]</b> tal�lat a lev�l <i>T�rzsben</i><BR>
[ENDIF]

[IF subj]
	<DD><B>[subj_count]</b> tal�lat a lev�l <i>T�rgy</i> mez�j�ben<BR>
[ENDIF]

[IF from]
	<DD><B>[from_count]</b> tal�lat a lev�l <i>Felad�ja</i> mez�j�ben<BR>
[ENDIF]

[IF date]
	<DD><B>[date_count]</b> tal�lat a lev�l <i>D�tum</i> mez�j�ben<BR>
[ENDIF]

</dl>

<FORM METHOD=POST ACTION="[path_cgi]">
<INPUT TYPE=hidden NAME=list		 VALUE="[list]">
<INPUT TYPE=hidden NAME=archive_name VALUE="[archive_name]">
<INPUT TYPE=hidden NAME=key_word     VALUE="[key_word]">
<INPUT TYPE=hidden NAME=how          VALUE="[how]">
<INPUT TYPE=hidden NAME=age          VALUE="[age]">
<INPUT TYPE=hidden NAME=case         VALUE="[case]">
<INPUT TYPE=hidden NAME=match        VALUE="[match]">
<INPUT TYPE=hidden NAME=limit        VALUE="[limit]">
<INPUT TYPE=hidden NAME=body_count   VALUE="[body_count]">
<INPUT TYPE=hidden NAME=date_count   VALUE="[date_count]">
<INPUT TYPE=hidden NAME=from_count   VALUE="[from_count]">
<INPUT TYPE=hidden NAME=subj_count   VALUE="[subj_count]">
<INPUT TYPE=hidden NAME=previous     VALUE="[searched]">

[IF body]
	<INPUT TYPE=hidden NAME=body Value="[body]">
[ENDIF]

[IF subj]
	<INPUT TYPE=hidden NAME=subj Value="[subj]">
[ENDIF]

[IF from]
	<INPUT TYPE=hidden NAME=from Value="[from]">
[ENDIF]

[IF date]
	<INPUT TYPE=hidden NAME=date Value="[date]">
[ENDIF]

[FOREACH u IN directories]
	<INPUT TYPE=hidden NAME=directories Value="[u]">
[END]

[IF continue]
	<INPUT NAME=action_arcsearch TYPE=submit VALUE="Keres�s folytat�sa">
[ENDIF]

<INPUT NAME=action_arcsearch_form TYPE=submit VALUE="�j keres�s">
</FORM>
<HR>
Keres�st az arch�vumban a <Font size=+1 color="--DARK_COLOR--"><i><A HREF="http://www.mhonarc.org/contrib/marc-search/">Marc-Search</a></i></font> a <B>MHonArc</B>
keres� program v�gezte.<p>


<A HREF="[path_cgi]/arc/[list]/[archive_name]"><B>Visszat�r�s a(z) [archive_name] arch�vumhoz
</B></A><br>
