<!-- RCS Identication ; $Revision$ ; $Date$ -->

<P>
<TABLE width=100% border="0" VALIGN="top">
<TR>
[IF is_owner]
<TD VALIGN="top" NOWRAP>
    <FORM ACTION="[path_cgi]" METHOD="POST">
      <INPUT TYPE="hidden" NAME="previous_action" VALUE="review">
      <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
      <INPUT TYPE="hidden" NAME="action" VALUE="add">
      <INPUT TYPE="text" NAME="email" SIZE="18">
      <INPUT TYPE="submit" NAME="action_add" VALUE="���">����<INPUT TYPE="checkbox" NAME="quiet">
    </FORM>
</TD>
<TD>
 <TABLE BORDER="0" CELLPADDING="1" CELLSPACING="0"><TR><TD BGCOLOR="#330099" VALIGN="top">
   <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
     <TR>
       <TD BGCOLOR="#ccccff" ALIGN="center" VALIGN="top">
         <FONT COLOR="#3366cc" SIZE="-1">
         <A HREF="[base_url][path_cgi]/add_request/[list]" ><b>��Ӷ��</b></A>
         </FONT>
       </TD>
     </TR>
   </TABLE></TD></TR>
 </TABLE>
</TD>

<TD>
 <TABLE BORDER="0" CELLPADDING="1" CELLSPACING="0"><TR><TD BGCOLOR="#330099" VALIGN="top">
   <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
     <TR>
       <TD BGCOLOR="#ccccff" ALIGN="center" VALIGN="top">
         <FONT COLOR="#3366cc" SIZE="-1">

         <A HREF="[base_url][path_cgi]/remind/[list]" onClick="request_confirm_link('[path_cgi]/remind/[list]', '��ȷ��Ҫ��ȫ����[total]�������߷��Ͷ��������ʼ���?'); return false;"><b>����ȫ��������</b></A>

         </FONT>
       </TD>
     </TR>
   </TABLE></TD></TR>
 </TABLE>
</TD>

[ENDIF]
</TR>
<TR>
<TD VALIGN="top" NOWRAP>
<FORM ACTION="[path_cgi]" METHOD="POST"> 
<INPUT TYPE="hidden" NAME="previous_action" VALUE="review">
<INPUT TYPE=hidden NAME=list VALUE="[list]">
<INPUT TYPE="hidden" NAME="action" VALUE="search">
<INPUT SIZE="18" NAME=filter VALUE="[filter]">
<INPUT TYPE="submit" NAME="action_search" VALUE="����">
[IF action=search]
<BR>�ҵ� [occurrence] ������ʵݱ�<BR>
[IF too_many_select]
ѡ��Χ�����޷���ʾѡ��
[ENDIF]
[ENDIF]
</FORM>
</TD>
</TR>
</TABLE>
<FORM ACTION="[path_cgi]" METHOD="POST">
 <INPUT TYPE="hidden" NAME="previous_action" VALUE="[action]">
 <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
 <INPUT TYPE=hidden NAME=list VALUE="[list]">

<TABLE WIDTH="100%" BORDER="0">
  <TR><TD ALIGN="left" NOWRAP>
  [IF is_owner]

    <!--INPUT TYPE="button" NAME="action_del" VALUE="Delete selected email addresses" onClick="request_confirm(this.form,'Do you really want to unsubscribe ALL selected subscribers ?')"-->

    <INPUT TYPE="submit" NAME="action_del" VALUE="ɾ��ѡ�е� Email ��ַ">

    <INPUT TYPE="checkbox" NAME="quiet">����
  [ENDIF]
  </TD>
  <TD>
  <TD WIDTH="100%">&nbsp;</TD>
  [IF action<>search]
  <TD NOWRAP>
	<INPUT TYPE="hidden" NAME="sortby" VALUE="[sortby]">
	<INPUT TYPE="submit" NAME="action_review" VALUE="ҳ���С">
	        <SELECT NAME="size">
                  <OPTION VALUE="[size]" SELECTED>[size]
		  <OPTION VALUE="25">25
		  <OPTION VALUE="50">50
		  <OPTION VALUE="100">100
		   <OPTION VALUE="500">500
		</SELECT>
   </TD>
   <TD>
   [IF prev_page]
    <A HREF="[path_cgi]/review/[list]/[prev_page]/[size]/[sortby]"><IMG SRC="/icons/left.gif" BORDER=0 ALT="ǰһҳ"></A>
   [ENDIF]
   [IF page]
     ��[page]ҳ����[total_page]ҳ
   [ENDIF]
   [IF next_page]
     <A HREF="[path_cgi]/review/[list]/[next_page]/[size]/[sortby]"><IMG SRC="/icons/right.gif" BORDER="0" ALT="��һҳ"></A>
   [ENDIF]
  [ENDIF]
  </TD></TR>
  </TABLE>

    <TABLE WIDTH="100%" BORDER="1">
      <TR BGCOLOR="#ccccff">
	[IF is_owner]
	   <TH><FONT SIZE="-1"><B>X</B></FONT></TH>
	[ENDIF]
        [IF sortby=email]
  	    <TH NOWRAP COLSPAN=2 BGCOLOR="#3366cc">
	    <FONT COLOR="#ffffff" SIZE="-1"><b>Email</b></FONT>
	[ELSE]
	    <TH NOWRAP COLSPAN=2>
	    <A HREF="[path_cgi]/review/[list]/1/[size]/email" >
	    <FONT SIZE="-1"><b>Email</b></A>
	[ENDIF]
	</TH>
        <TH><FONT SIZE="-1"><B>����</B></FONT>
	</TH>
        [IF is_owner]
	  <TH><FONT SIZE="-1"><B>����</B></FONT>
	  </TH>
	  [IF sortby=date]
  	    <TH NOWRAP BGCOLOR="#3366cc">
	    <FONT COLOR="#ffffff" SIZE="-1"><b>����</b></FONT>
	  [ELSE]
	    <TH NOWRAP><FONT SIZE="-1">
	    <A HREF="[path_cgi]/review/[list]/1/[size]/date" >
	    <b>����</b></A></FONT>
	  [ENDIF]
          </TH>
        [ENDIF]
      </TR>
      
      [FOREACH u IN members]
        <TR>
	 [IF is_owner]
	    <TD>
	      [IF action=search]
	        <INPUT TYPE=checkbox name="email" value="[u->escaped_email]" CHECKED>
	      [ELSE]
	        <INPUT TYPE=checkbox name="email" value="[u->escaped_email]">
	      [ENDIF]
	    </TD>
	 [ENDIF]
	 [IF u->bounce]
	  <TD NOWRAP><FONT SIZE=-1>
	 
	      [IF is_owner]
		<A HREF="[path_cgi]/editsubscriber/[list]/[u->escaped_email]/review">[u->email]</A>
	      [ELSE]
 	        [u->email]
 	      [ENDIF]
	  </FONT></TD>
            <TD ALIGN="right"BGCOLOR="#ff6666"><FONT SIZE=-1>
		<FONT COLOR="#ffffff"><B>����</B></FONT>
	    </TD>

	 [ELSE]
	  <TD COLSPAN=2 NOWRAP><FONT SIZE=-1>
	      [IF is_owner]
		<A HREF="[path_cgi]/editsubscriber/[list]/[u->escaped_email]/review">[u->email]</A>
	      [ELSE]
	        [u->email]
	      [ENDIF]
	  </FONT></TD>
	 [ENDIF]

	  <TD>
             <FONT SIZE=-1>
	        [u->gecos]&nbsp;
	     </FONT>
          </TD>
	  [IF is_owner]
  	    <TD ALIGN="center"><FONT SIZE=-1>
  	      [u->reception]
	    </FONT></TD>
	    <TD ALIGN="center"NOWRAP><FONT SIZE=-1>
	      [u->date]
	    </FONT></TD>
       	  [ENDIF]
        </TR>
        [END]


      </TABLE>
    <TABLE WIDTH=100% BORDER=0>
    <TR><TD ALIGN="left">
      [IF is_owner]

        <!--INPUT TYPE="button" NAME="action_del" VALUE="Delete selected email addresses" onClick="request_confirm(this.form,'Do you really want to unsubscribe ALL selected subscribers ?')"-->

	<INPUT TYPE="submit" NAME="action_del" VALUE="Delete selected email addresses">

        <INPUT TYPE="checkbox" NAME="quiet"> ����
      [ENDIF]
    </TD>

   [IF action<>search]
    <TD ALIGN="right">
       [IF prev_page]
	 <A HREF="[path_cgi]/review/[list]/[prev_page]/[size]/[sortby]"><IMG SRC="/icons/left.gif" BORDER=0 ALT="ǰһҳ"></A>
       [ENDIF]
       [IF page]
  	  page [page] / [total_page]
       [ENDIF]
       [IF next_page]
	  <A HREF="[path_cgi]/review/[list]/[next_page]/[size]/[sortby]"><IMG SRC="/icons/right.gif" BORDER=0 ALT="��һҳ"></A>
       [ENDIF]
    </TD>
   [ENDIF]
    </TR>
    </TABLE>
    </FORM>






