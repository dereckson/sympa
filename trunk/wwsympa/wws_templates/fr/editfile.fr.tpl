<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM ACTION="[path_cgi]" METHOD="POST">

[IF file]
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
  <INPUT TYPE="hidden" NAME="file" VALUE="[file]">
<TEXTAREA NAME="content" COLS=80 ROWS=25>
[INCLUDE filepath]
</TEXTAREA>
  <INPUT TYPE="submit" NAME="action_savefile" VALUE="Sauvegarder">

[ELSE]
Cette fonction vous permet d'�diter certains fichiers associ�s � votre liste (messages de service).
Par d�faut, SYMPA utilise des messages de service par d�faut.
Dans ce cas, le fichier correpondant sp�cifique � votre liste est vide.
<BR>
Pour modifier un message personnalis�, choisissez-le dans la liste d�roulante situ�e � gauche du bouton "Editer", puis cliquez sur ce bouton.
Si le message personnalis� n'existe pas encore, le plus simple est de coller le texte du message par d�faut dans le champ d'�dition, puis de le modifier.
<BR>
Dans les messages de services �num�r�s ci-dessous, vous pouvez utiliser des <A HREF="[path_cgi]/help/variables" onClick="window.open('','wws_help','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,copyhistory=no,width=400,height=200')" TARGET="wws_help">variables</A>.

Vous pouvez �diter ci-dessous les messages de services et d'autres fichiers associ�s
� votre liste :<BR><BR>

<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	     <SELECT NAME="file">
	      [FOREACH f IN files]
	        <OPTION VALUE="[f->NAME]" [f->selected]>[f->complete]
	      [END]
	    </SELECT>
	    <INPUT TYPE="submit" NAME="action_editfile" VALUE="Editer">

<P>
[PARSE '--ETCBINDIR--/wws_templates/help_editfile.fr.tpl']

[ENDIF]
</FORM>
