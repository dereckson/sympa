<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF help_topic]
 [PARSE help_template]

[ELSE]
<BR>
����������������ʼ��ʵݱ������ <B>[conf->email]@[conf->host]</B>��
<BR><BR>
�� Sympa ����������(ͨ���ʼ�����)��ͬ�Ĺ��ܿ��ԴӸ߼�����û�������ʹ�á�
WWSympa �ṩ�ɶ��ƵĻ�������ʹ�����¹���: 

<UL>
<LI><A HREF="[path_cgi]/pref">��ѡ��</A>: �û���ѡ����ṩ��ȷ����ݵ��û���

<LI><A HREF="[path_cgi]/lists">�����ʵݱ�</A>: ���������ṩ�Ĺ����ʵݱ�

<LI><A HREF="[path_cgi]/which">�����ĵ��ʵݱ�</A>: ����Ϊ�����߻�ӵ���ߵĻ�����

<LI><A HREF="[path_cgi]/loginrequest">��¼</A>��<A HREF="[path_cgi]/logout">ע��</A>: �� WWSympa �ϵ�¼���˳���
</UL>

<H2>��¼</H2>

����֤���(<A HREF="[path_cgi]/loginrequest">��¼</A>)ʱ�����ṩ���� Email ��ַ����Ӧ�Ŀ��
<BR><BR>
һ��ͨ����֤��һ����������¼��Ϣ�� <I>cookie</I> ʹ���ܹ��������� WWSympa��
��� <I>cookie</I> �������ڿ���������<A HREF="[path_cgi]/pref">��ѡ��</A>��ָ����

<BR><BR>
���������κ�ʱ��ʹ��<A HREF="[path_cgi]/logout">ע��</A>������ע��(ɾ��
<I>cookie</I>)��

<H5>��¼����</H5>

<I>�Ҳ����ʵݱ�Ķ�����</I><BR>
������û���� Sympa ���û����ݿ��еǼ����޷���¼��
�����������һ���ʵݱ�WWSympa ������һ����ʼ���
<BR><BR>

<I>��������һ���ʵݱ�Ķ����ߣ�������û�п���</I><BR>
Ҫ�յ�����:
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>
<BR><BR>

<I>�������˿���</I><BR>
WWSympa ����ͨ�������ʼ�������������:
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>

<P>

���Ҫ��ϵ����������Ա: <A HREF="mailto:listmaster@[conf->host]">listmaster@[conf->host]</A>
[ENDIF]













