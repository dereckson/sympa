<!-- RCS Identication ; $Revision$ ; $Date$ -->

  <FORM ACTION="[path_cgi]" METHOD=POST>

  ����<FONT COLOR="--DARK_COLOR--">[subscriber->date]</FONT>�俪ʼ����  <BR><BR>
     <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
     ����ģʽ: 
     <SELECT NAME="reception">
        [FOREACH r IN reception]
          <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
        [END]
     </SELECT>
     <BR>�ɼ���:
     <SELECT NAME="visibility">
        [FOREACH r IN visibility]
          <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
        [END]
     </SELECT>

     <BR>
     <INPUT TYPE="submit" NAME="action_set" VALUE="����">
     
</FORM>
