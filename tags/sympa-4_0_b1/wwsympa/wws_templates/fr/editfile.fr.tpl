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
