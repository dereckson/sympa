<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF action=search_list]
  [occurrence] egyez�st tal�ltam<BR><BR>
[ELSIF action=search_user]
  <B>[email]</B> a k�vetkez� list�k tagja
[ENDIF]

<TABLE BORDER="0" WIDTH="100%">
   [FOREACH l IN which]
     <TR>
     [IF l->admin]
       <TD BGCOLOR="[dark_color]">
          <TABLE BORDER="0" WIDTH="100%" CELLSPACING="0" CELLPADDING="1">
           <TR><TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top">
             <FONT COLOR="[selected_color]" SIZE="-1">
              <A HREF="[path_cgi]/admin/[l->NAME]" ><b>admin</b></A>
         </FONT>
       </TD>
     </TR>
 </TABLE>
</TD>
     [ELSE]
       <TD>&nbsp;</TD>
     [ENDIF] 
     <TD WIDTH="100%" ROWSPAN="2">
     <A HREF="[path_cgi]/info/[l->NAME]" ><B>[l->NAME]@[l->host]</B></A>
     <BR>
     [l->subject]
     </TD></TR>
     <TR><TD>&nbsp;</TD></TR>
   [END]
</TABLE>

<BR> 
[IF action=which] 
[IF ! which]
&nbsp;&nbsp;<FONT COLOR="[dark_color]"><B>[user->email]</B> c�mmel nem tal�lhat� listatag!</FONT>
<BR>
[ENDIF]

[IF unique <> 1]
<TABLE>
&nbsp;&nbsp;<FONT COLOR="[dark_color]">Tekintsd meg azon listatags�gaidat, ahol az e-mail c�med a k�vetkez�</FONT><BR>
<BR><BR> 

<TR>
 <FORM METHOD=POST ACTION="[path_cgi]">

[FOREACH email IN alt_emails]
<INPUT NAME="email" TYPE=hidden VALUE="[email->NAME]">
&nbsp;&nbsp;<A HREF="[path_cgi]/change_identity/[email->NAME]/which">[email->NAME]</A>
<BR>
[END]
</FORM>
</TR>
</TABLE>

<BR>

<TABLE>
<TR>
&nbsp;&nbsp;<FONT COLOR="[dark_color]">�ll�tsd �t mindenhol a feliratkoz�si c�medet  <B>[user->email] c�mre</B></FONT><BR> 
&nbsp;&nbsp;<FONT COLOR="[dark_color]">Ez azt jelenti, hogy a Sympa levelez�list�kon mindenhol ugyanaz lesz a feliratkoz�si e-mail c�med �s be�ll�t�sod.</FONT>

<TR>
<TD>
 <FORM ACTION="[path_cgi]" METHOD=POST>
 &nbsp;&nbsp;<INPUT TYPE="submit" NAME="action_unify_email" VALUE="Valider"></FONT>
</FORM>
</TD>
</TR>
<BR>
</TABLE>
[ENDIF]
[ENDIF]
