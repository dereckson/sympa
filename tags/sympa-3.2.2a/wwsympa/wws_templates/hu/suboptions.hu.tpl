<!-- RCS Identication ; $Revision$ ; $Date$ -->

  <FORM ACTION="[path_cgi]" METHOD=POST>

   <FONT COLOR="#330099">[subscriber->date]</FONT> �ta vagy feliratkozva. <BR><BR>
     <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
     Fogad�si m�d: 
     <SELECT NAME="reception">
        [FOREACH r IN reception]
          <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
        [END]
     </SELECT>
     <BR>Nyilv�noss�g :
     <SELECT NAME="visibility">
        [FOREACH r IN visibility]
          <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
        [END]
     </SELECT>

     <BR>
     <INPUT TYPE="submit" NAME="action_set" VALUE="Friss�t">
     
</FORM>
