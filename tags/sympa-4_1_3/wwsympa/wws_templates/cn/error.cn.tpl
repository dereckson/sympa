<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH error IN errors]

[IF error->msg=unknown_action]
[error->action] : δ֪����

[ELSIF error->msg=unknown_list]
[error->list] : δ֪�ʵݱ�

[ELSIF error->msg=already_login]
���Ѿ��� [error->email] ��¼

[ELSIF error->msg=no_email]
���������ĵ����ʼ���ַ

[ELSIF error->msg=incorrect_email]
��ַ��[error->email]���Ǵ����

[ELSIF error->msg=incorrect_listname]
��[error->listname]��: ������ʵݱ���

[ELSIF error->msg=no_passwd]
���������Ŀ���

[ELSIF error->msg=user_not_found]
��[error->email]��: δ֪�û�

[ELSIF error->msg=user_not_found]
��[error->email]�����Ƕ�����

[ELSIF error->msg=passwd_not_found]
�û���[error->email]��û�п���

[ELSIF error->msg=incorrect_passwd]
����Ŀ����ȷ

[ELSIF error->msg=uncomplete_passwd]
����Ŀ������

[ELSIF error->msg=no_user]
����Ҫ�ȵ�¼

[ELSIF error->msg=may_not]
[error->action]: ��������������������
[IF ! user->email]
<BR>����Ҫ�ȵ�¼
[ENDIF]

[ELSIF error->msg=no_subscriber]
�ʵݱ�û�ж�����

[ELSIF error->msg=no_bounce]
�ʵݱ�û�б����ŵĶ�����

[ELSIF error->msg=no_page]
û��ҳ [error->page]

[ELSIF error->msg=no_filter]
ȱ�ٹ���

[ELSIF error->msg=file_not_editable]
[error->file]: �ļ����ɱ༭

[ELSIF error->msg=already_subscriber]
���Ѿ��������ʵݱ� [error->list]

[ELSIF error->msg=user_already_subscriber]
[error->email] �Ѿ��������ʵݱ� [error->list] 

[ELSIF error->msg=failed_add]
����ʹ���� [error->user] ʧ��

[ELSIF error->msg=failed]
[error->action]: ����ʧ��

[ELSIF error->msg=not_subscriber]
[IF error->email]
  ���Ƕ�����: [error->email]
[ELSE]
�������ʵݱ� [error->list] �Ķ�����
[ENDIF]

[ELSIF error->msg=diff_passwd]
�������һ��

[ELSIF error->msg=missing_arg]
ȱ�ٲ��� [error->argument]

[ELSIF error->msg=no_bounce]
�û� [error->email] û������

[ELSIF error->msg=update_privilege_bypassed]
����û��Ȩ�޵�������޸���һ������: [error->pname]

[ELSIF error->msg=config_changed]
�����ļ��Ѿ��� [error->email] �޸ġ��޷�Ӧ�������޸�

[ELSIF error->msg=syntax_errors]
���в����﷨����: [error->params]

[ELSIF error->msg=no_such_document]
[error->path]: û�д��ļ���Ŀ¼

[ELSIF error->msg=no_such_file]
[error->path] : û�д��ļ�

[ELSIF error->msg=empty_document] 
�޷���ȡ [error->path] : �յ��ĵ�

[ELSIF error->msg=no_description] 
û��ָ������

[ELSIF error->msg=no_content]
����: ���ṩ�������ǿյ�

[ELSIF error->msg=no_name]
û��ָ������

[ELSIF error->msg=incorrect_name]
[error->name]: ����ȷ������

[ELSIF error->msg = index_html]
��û�б���Ȩ�ϴ�һ�� INDEX.HTML �� [error->dir] 

[ELSIF error->msg=synchro_failed]
���������Ѿ��ı䡣�޷�Ӧ�������޸�

[ELSIF error->msg=cannot_overwrite] 
�޷������ļ� [error->path] : [error->reason]

[ELSIF error->msg=cannot_upload] 
�޷��ϴ��ļ� [error->path] : [error->reason]

[ELSIF error->msg=cannot_create_dir] 
�޷�����Ŀ¼ [error->path] : [error->reason]

[ELSIF error->msg=full_directory]
ʧ��: [error->directory] ��Ϊ��

[ELSIF error->msg=init_passwd]
����δѡȡ����, ��Ҫ��һ��ԭ�ȿ��������
 
[ELSIF error->msg=change_email_failed]
�޷����� [error->list] �ĵ���λַ

[ELSIF error->msg=change_email_failed_because_subscribe_not_allowed]
�޷�������̳ '[error->list]' �Ķ���λַ,
��Ϊ�ѽ�ֹ���µ�λַ����.

[ELSIF error->msg=change_email_failed_because_unsubscribe_not_allowed]
�޷�������̳ '[error->list]' �Ķ���λַ,
��Ϊ�ѽ�ֹȡ������.

[ELSE]
[error->msg]
[ENDIF]

<BR>
[END]
