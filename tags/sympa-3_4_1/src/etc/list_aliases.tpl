#------------------------------ [list->name]: list alias created [date]
[IF is_default_domain]
[list->name]: "| --MAILERPROGDIR--/queue [list->name]@[list->domain]"
[list->name]-request: "| --MAILERPROGDIR--/queue [list->name]-request@[list->domain]"
[list->name]-editor: "| --MAILERPROGDIR--/queue [list->name]-editor@[list->domain]"
#[list->name]-subscribe: "| --MAILERPROGDIR--/queue [list->name]-subscribe@[list->domain]"
[list->name]-unsubscribe: "| --MAILERPROGDIR--/queue [list->name]-unsubscribe@[list->domain]"
[list->name]-owner: "| --MAILERPROGDIR--/bouncequeue [list->name]-unsubscribe@[list->domain]"
[ELSE]
[list->domain]-[list->name]: "| --MAILERPROGDIR--/queue [list->name]@[list->domain]"
[list->domain]-[list->name]-request: "| --MAILERPROGDIR--/queue [list->name]-request@[list->domain]"
[list->domain]-[list->name]-editor: "| --MAILERPROGDIR--/queue [list->name]-editor@[list->domain]"
#[list->domain]-[list->name]-subscribe: "| --MAILERPROGDIR--/queue [list->name]-subscribe@[list->domain]"
[list->domain]-[list->name]-unsubscribe: "| --MAILERPROGDIR--/queue [list->name]-unsubscribe@[list->domain]"
[list->domain]-[list->name]-owner: "| --MAILERPROGDIR--/bouncequeue [list->name]@[list->domain]"
[ENDIF]