
<!-- begin arc_manage.fr.tpl -->
<Hr><b>Gestion des Archives</b>
<BR>
S�lectionnez ci-dessous les mois d'Archives que vous voulez supprimer ou t�l�charger (au format Zip) :
<DL>
<DT>Selection des Archives :
<FORM METHOD=POST ACTION="[path_cgi]">
<SELECT NAME="directories" MULTIPLE SIZE=4>    

	[FOREACH u IN yyyymm]

	<OPTION	VALUE="[u]">[u]

	[END] 
	
</SELECT>
<INPUT NAME=list TYPE=hidden VALUE="[list]">
<INPUT NAME="zip" TYPE=hidden VALUE="0">
<INPUT Type="submit" NAME="action_arc_download" VALUE="T�l�charger le Zip">
<INPUT Type="submit" NAME="action_arc_delete" VALUE="D�truire les mois s�lectionn�s " onClick="return dbl_confirm(this.form,'Etes-vous sur(e) de vouloir supprimer les archives s�lectionn�es ?','Voulez-vous t�l�charger le Zip des archives S�lectionn�es avant suppression?')">
</DL>
</FORM>
<Hr>
<!-- end  arc_manage.fr.tpl -->