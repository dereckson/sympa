<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF help_topic]
 [PARSE help_template]

[ELSE]
<BR>
WWSympa le permite el acceso a su entorno en el servidor de listas de correo
<B>[conf->email]@[conf->host]</B>.
<BR><BR>
Funciones, equivalentes a los comandos del robot Sympa, son accesibles desde la parte superior del interfaz de usario.
WWSympa le facilita un entorno personalizado con acceso a las siguientes funciones :

<UL>
<LI><A HREF="[path_cgi]/pref">Preferencias</A> : preferencias del usuario. Esto es s�lo para usuarios ya identificados.

<LI><A HREF="[path_cgi]/lists">Listas P�blicas </A> : directorio de las listas disponibles en este servidor

<LI><A HREF="[path_cgi]/which">Sus subscripciones</A> : su entorno como subscriptor o propietario

<LI><A HREF="[path_cgi]/loginrequest">Login</A> / <A HREF="[path_cgi]/logout">Logout</A> : Entrar / Abandonar de WWSympa.
</UL>

<H2>Login</H2>

Durante la autentificaci�n (<A HREF="[path_cgi]/loginrequest">Login</A>), entre su email y su contrase�a.
<BR><BR>
Una vez autentificado, una <I>cookie</I> conteniendo su informaci�n del login permite el acceso a WWSympa. La duraci�n de esta <I>cookie</I> se puede cambiar desde <A HREF="[path_cgi]/pref">sus preferencias</A>. 

<BR><BR>
Puede abandonar (logout) en cualquier momento usando la funci�n de <A HREF="[path_cgi]/logout">logout</A>

<H5>Problemas con Login issues</H5>

<I>Yo no soy subscriptor de ninguna lista</I><BR>
Vd. no est� registrado en la base de datos de Sympa y por tanto no puede hacer un login.
Si se subscribe a una lista, WWSympa le asignar� una contrase�a inicial.
<BR><BR>

<I>Yo soy subscriptor de al menos una lista pero no tengo contrase�a</I><BR>
Para recibir su contrase�a : 
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>
<BR><BR>

<I>Olvid� mi contrase�a</I><BR>

WWSympa le puede recordar su contrase�a por correo :
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>

<P>
To contact this service administrator : <A HREF="mailto:listmaster@[conf->host]">listmaster@[conf->host]</A>
[ENDIF]










