[FOREACH notice IN notices]

[IF notice_msg=sent_to_owner]
���������Ѿ���ת�����ʵݱ�������

[ELSIF notice_msg=performed]
[notice->action]: �����ɹ�

[ELSIF notice_msg=list_config_updated]
�����ļ��Ѿ�������

[ELSIF notice_msg=upload_success] 
�ɹ��ϴ��ļ� [notice->path] !

[ELSIF notice_msg=save_success] 
�ļ� [notice->path] �ѱ���

[ELSE]
[notice->msg]

[ENDIF]

<BR>
[END]




