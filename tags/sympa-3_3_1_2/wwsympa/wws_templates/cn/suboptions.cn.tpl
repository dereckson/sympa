<!-- RCS Identication ; $Revision$ ; $Date$ -->

  <FORM ACTION="[path_cgi]" METHOD=POST>

  ����<FONT COLOR="[dark_color]">[subscriber->date]</FONT>�俪ʼ����  <BR><BR>
     <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
     ����ģʽ: 
     <SELECT NAME="reception">
        [FOREACH r IN reception]
          <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
        [END]
     </SELECT>

     [PARSE '--ETCBINDIR--/wws_templates/button_header.tpl']
     <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center"> 
      <A HREF="[path_cgi]/nomenu/help/user_options" onClick="window.open('','wws_help','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,copyhistory=no,width=400,height=200')" TARGET="wws_help">
     <FONT SIZE=-1><B>����</B></FONT></A>
     </TD>
     [PARSE '--ETCBINDIR--/wws_templates/button_footer.tpl']

     <BR>�ɼ���:
     <SELECT NAME="visibility">
        [FOREACH r IN visibility]
          <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
        [END]
     </SELECT>

     <BR>
     <INPUT TYPE="submit" NAME="action_set" VALUE="����">
     
</FORM>
