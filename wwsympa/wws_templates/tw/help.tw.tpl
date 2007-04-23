<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF help_topic]
 [PARSE help_template]

[ELSE]
<BR>
您可以在這裡訪問郵件 Mailing List  Server  <B>[conf->email]@[conf->host]</B>。
<BR><BR>
和 Sympa 機器人命令(通過郵件進行)相同的功能可以從高級別的用戶界面上使用。
WWSympa 提供可自訂的環境，可使用以下功能: 

<UL>
<LI><A HREF="[path_cgi]/pref">選項</A>: 用戶選項。僅提供給確認身份的用戶。

<LI><A HREF="[path_cgi]/lists">公開 Mailing List </A>:  Server 上提供的公開 Mailing List 。

<LI><A HREF="[path_cgi]/which">您訂閱的 Mailing List </A>: 您作為訂閱者或擁有者的環境。

<LI><A HREF="[path_cgi]/loginrequest"> Login </A>或<A HREF="[path_cgi]/logout">Logout</A>: 從 WWSympa 上 Login 或退出。
</UL>

<H2> Login </H2>

[IF auth=classic]
在驗証身份(<A HREF="[path_cgi]/loginrequest"> Login </A>)時，請提供您的 Email 地址和相應的密碼。
<BR><BR>
一旦通過驗証，一個包含您 Login 訊息的 <I>cookie</I> 使您能夠持續訪問 WWSympa。
這個 <I>cookie</I> 的生存期可以在您的<A HREF="[path_cgi]/pref">選項</A>中指定。

<BR><BR>
[ENDIF]

您可以在任何時候使用<A HREF="[path_cgi]/logout">Logout�</>功能 Logout <I>cookie</I>)。

<H5> Login 問題</H5>

<I>我不是 Mailing List 的訂閱者</I><BR>
所以您沒有在 Sympa 的用戶 Database 中登記且無法 Login 。
如果您訂閱了一個 Mailing List ，WWSympa 將給您一個初始密碼。
<BR><BR>

<I>我是至少一個 Mailing List 的訂閱者，但是我沒有密碼</I><BR>
要收到密碼:
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>
<BR><BR>

<I>我忘記了密碼</I><BR>
WWSympa 可以通過電子郵件來告訴您密碼:
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>

<P>

如果要聯絡 Server 管理員: <A HREF="mailto:listmaster@[conf->host]">listmaster@[conf->host]</A>
[ENDIF]













