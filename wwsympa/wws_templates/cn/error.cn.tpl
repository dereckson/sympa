<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF error_msg=unknown_action]
[error->action] : δ֪����

[ELSIF error_msg=unknown_list]
[error->list] : δ֪�ʵݱ�

[ELSIF error_msg=already_login]
���Ѿ��� [error->email] ��¼

[ELSIF error_msg=no_email]
���������ĵ����ʼ���ַ

[ELSIF error_msg=incorrect_email]
��ַ��[error->email]���Ǵ����

[ELSIF error_msg=incorrect_listname]
��[error->listname]��: ������ʵݱ���

[ELSIF error_msg=no_passwd]
���������Ŀ���

[ELSIF error_msg=user_not_found]
��[error->email]��: δ֪�û�

[ELSIF error_msg=user_not_found]
��[error->email]�����Ƕ�����

[ELSIF error_msg=passwd_not_found]
�û���[error->email]��û�п���

[ELSIF error_msg=incorrect_passwd]
����Ŀ����ȷ

[ELSIF error_msg=no_user]
����Ҫ�ȵ�¼

[ELSIF error_msg=may_not]
[error->action]: ��������������������
[IF ! user->email]
<BR>����Ҫ�ȵ�¼
[ENDIF]

[ELSIF error_msg=no_subscriber]
�ʵݱ�û�ж�����

[ELSIF error_msg=no_bounce]
�ʵݱ�û�б����ŵĶ�����

[ELSIF error_msg=no_page]
û��ҳ [error->page]

[ELSIF error_msg=no_filter]
ȱ�ٹ���

[ELSIF error_msg=file_not_editable]
[error->file]: �ļ����ɱ༭

[ELSIF error_msg=already_subscriber]
���Ѿ��������ʵݱ� [error->list]

[ELSIF error_msg=user_already_subscriber]
[error->email] �Ѿ��������ʵݱ� [error->list] 

[ELSIF error_msg=failed]
����ʧ��

[ELSIF error_msg=not_subscriber]
�������ʵݱ� [error->list] �Ķ�����

[ELSIF error_msg=diff_passwd]
�������һ��

[ELSIF error_msg=missing_arg]
ȱ�ٲ��� [error->argument]

[ELSIF error_msg=no_bounce]
�û� [error->email] û������

[ELSIF error_msg=update_privilege_bypassed]
����û��Ȩ�޵�������޸���һ������: [error->pname]

[ELSIF error_msg=config_changed]
�����ļ��Ѿ��� [error->email] �޸ġ��޷�Ӧ�������޸�

[ELSIF error_msg=syntax_errors]
���в����﷨����: [error->params]

[ELSIF error_msg=no_such_document]
[error->path]: û�д��ļ���Ŀ¼

[ELSIF error_msg=no_such_file]
[error->path] : û�д��ļ�

[ELSIF error_msg=empty_document] 
�޷���ȡ [error->path] : �յ��ĵ�

[ELSIF error_msg=no_description] 
û��ָ������

[ELSIF error_msg=no_content]
����: ���ṩ�������ǿյ�

[ELSIF error_msg=no_name]
û��ָ������

[ELSIF error_msg=incorrect_name]
[error->name]: ����ȷ������

[ELSIF error_msg = index_html]
��û�б���Ȩ�ϴ�һ�� INDEX.HTML �� [error->dir] 

[ELSIF error_msg=synchro_failed]
���������Ѿ��ı䡣�޷�Ӧ�������޸�

[ELSIF error_msg=cannot_overwrite] 
�޷������ļ� [error->path] : [error->reason]

[ELSIF error_msg=cannot_upload] 
�޷��ϴ��ļ� [error->path] : [error->reason]

[ELSIF error_msg=cannot_create_dir] 
�޷�����Ŀ¼ [error->path] : [error->reason]

[ELSIF error_msg=full_directory]
ʧ��: [error->directory] ��Ϊ��

[ELSIF error_msg=password_sent]
�Ѿ��õ����ʼ������Ŀ���͸���

 

[ELSE]
[error_msg]
[ENDIF]
