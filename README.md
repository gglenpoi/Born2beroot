# Born2beroot

## About

Born2beRoot - это введение в виртуализацию и системное администрирование. Цель здесь - создать виртуальную машину, которая является сервером, с последней версией Debian, реализующей строгие правила и минимально необходимые службы.

## Table of Contents

1. [UFW](#ufw)
2. [SSH](#ssh)
3. [Apparmor](#apparmor)
4. [Sudo](#sudo)
5. [Passwords policy](#passwords-policy)
6. [Bash script-monitoring](#Bash-script-monitoring)
7. [WordPress](#WordPress)

## UFW

### Requirements:

> Вы должны настроить свою операционную систему с помощью брандмауэра UFW и, таким образом, оставить открытым только порт 4242.

Step 0:

```bash
apt update
```

Install UFW

```bash
apt install ufw -y
```

Включить брандмауэр

```bash
ufw enable
```

Разрешить входящее подключение с использованием порта 4242 (для ssh)

```bash
ufw allow 4242
```

Проверьте статус UFW

```bash
ufw status verbose
```



## SSH

### Requirements:

> Служба SSH будет запущена только на порту 4242. По соображениям безопасности подключение по SSH от имени root должно быть невозможно.

Install ssh

```bash
apt install openssh-server
```

Start ssh

```bash
systemctl start sshd
```

Изменить порт по умолчанию на 4242 и заблокировать подключение SSH от имени root

```bash
vi /etc/ssh/sshd_config
```

Изменить:

```
13 #Port 22
32 #PermitRootLogin prohibit-password
```

на

```
13 Port 4242
32 PermitRootLogin no
```

Restart ssh

```bash
service ssh restart
```

Check status

```bash
systemctl status sshd
```

Теперь мы можем подключиться

```bash
ssh <user_name>@<ip_addres> -p <port>
```

```bash
ssh gradagas@localhost -p 4242
```



## Apparmor

Requirements:

> <...> AppArmor для Debian также должно быть запущено при запуске.

install apparmor utils and profiles

```bash
apt install apparmor-utils apparmor-profiles -y
```

Check apparmor

```bash
apparmor_status
```



## Sudo

Requirements:

> - Аутентификация с помощью sudo должна быть ограничена 3 попытками в случае неверного пароля.
> - Пользовательское сообщение по вашему выбору должно отображаться, если при использовании sudo возникает ошибка из-за неправильного пароля.
> - Каждое действие с использованием sudo должно быть заархивировано, как входные, так и выходные данные. Файл журнала должен быть сохранен в папке /var/log/sudo/.
> - Режим TTY должен быть включен по соображениям безопасности.
> - Также по соображениям безопасности пути, которые могут использоваться sudo, должны быть ограничены. Пример: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin

Установка sudo

```bash
apt install sudo
```

Добавим пользователя в группу sudoers

```bash
usermod -aG sudo <user_name>
```

или

```bash
adduser <username> sudo
```

Проверим пользователя в группе

```bash
cat /etc/group
```

Настройка sudo.

```bash
EDITOR=vim /usr/sbin/visudo
```

Добавим в файл нижеприведенные строки

```bash
Defaults	passwd_tries=3
Defaults	badpass_message="<your_origin_badpass_message>"
Defaults	logfile=/var/log/sudo
Defaults	iolog_dir=/var/log/sudo
Defaults	log_input
Defaults	log_output
Defaults	requiretty
Defaults	secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"
```



## Passwords policy

### Password Age policy

Requirements:

> - Срок действия пароля должен истекать каждые 30 дней.
> - Минимальное количество дней, разрешенное для изменения пароля, будет установлено равным 2.
> - Пользователь должен получить предупреждающее сообщение за 7 дней до истечения срока действия его пароля.
>

```bash
vim /etc/login.defs
```

Изменим нижеприведенные строки в файле

```bash
160 PASS_MAX_DAYS   99999
161 PASS_MIN_DAYS   0
162 PASS_WARN_AGE   7
```

на

```bash
160 PASS_MAX_DAYS   30
161 PASS_MIN_DAYS   2
162 PASS_WARN_AGE   7
```

Эти правила будут применяться **только** к новым пользователям. Чтобы изменить возрастную политику, существующие пользователи используют:

To change PASS_MAX_DAYS

```bash
chage -M <num_days> <user_name>
```

To change PASS_MIN_DAYS

```bash
chage -m <num_days> <user_name>
```

Check

```bash
chage -l <user_name>
```



#### Password Strength policy

Requirements:

> - Длина вашего пароля должна составлять не менее 10 символов. Оно должно содержать заглавную букву и цифру. Кроме того, он не должен содержать более 3 последовательных одинаковых символов.
> - Пароль не должен содержать имени пользователя.
> - Следующее правило не применяется к паролю root: пароль должен содержать не менее 7 символов, которые не являются частью предыдущего пароля.
> - Конечно, ваш пароль root должен соответствовать этой политике.
>



Установите пакет *libpam-pwquality*.

```bash
apt install libpam-pwquality -y
```

Редактировать конфигурационный файл

```bash
vim /etc/security/pwquality.conf
```

Желаемые настройки:

```bash
difok = 7
minlen = 10
dcredit = -1
ucredit = -1
maxrepeat = 3
usercheck = 1
enforce_for_root = 1
```

## Bash script-monitoring

Requirements:

> При запуске сервера скрипт будет отображать некоторую информацию (перечисленную ниже) на всех терминалах каждые 10 минут (взгляните на wall). Баннер необязателен. Ошибка не должна быть видна.
>
> Ваш скрипт всегда должен иметь возможность отображать следующую информацию:
>
> - Архитектура вашей операционной системы и версия ее ядра.
> - Количество физических процессоров.
> - Количество виртуальных процессоров.
> - Текущая доступная оперативная память на вашем сервере и коэффициент ее использования в процентах.
> - Текущая доступная память на вашем сервере и коэффициент ее использования в процентах.
> - Текущий коэффициент использования ваших процессоров в процентах.
> - Дата и время последней перезагрузки.
> - Активен ли LVM или нет.
> - Количество активных подключений.
> - Количество пользователей, использующих сервер.
> - IPv4-адрес вашего сервера и его MAC-адрес (управление доступом к мультимедиа).
> - Количество команд, выполненных с помощью программы sudo.

```bash
apt install net-tools
```

Создаем monitoring.sh (reference [here](https://github.com/HEADLIGHTER/Born2BeRoot-42/blob/main/monitoring.sh))

```bash
vim /usr/local/bin/monitoring.sh
```

Сделайте файл исполняемым

```bash
chmod +x /usr/local/bin/monitoring.sh
```

Сделайте файл исполняемым, добавьте скрипт в cron

```bash
crontab -e
```

Добавьте в открытый файл-конфигурационную строку ниже

```bash
*/10 * * * * root /usr/local/bin/monitoring.sh
```

Проверьте работу скрипта

```bash
grep CRON /var/log/syslog
```



## Wordpress

Requirements:

> Создайте функциональный веб-сайт на WordPress со следующими сервисами: lighttpd, MariaDB и PHP.

### PHP

Install PHP

```bash
apt install php7.4 php7.4-fpm php7.4-mysql php7.4-cli php7.4-cgi php7.4-curl php7.4-xml -y
```

### lighttpd

Install lighttpd

```bash
apt install lighttpd -y
```

Настройка lighttpd

```bash
lighttpd-enable-mod fastcgi
```

```bash
lighttpd-enable-mod fastcgi-php
```

```bash
lighty-enable-mod accesslog
```

Включить перезапись в Lighttpd

```bash
vim /etc/lighttpd/lighttpd.conf
```

добавим `server.modules`

```bash
"mod_rewrite",
```

### MariaDB

Install MariaDB

```bash
apt install mariadb-server mariadb-client -y
```

```bash
mysql_secure_installation
```

создадим новый database

```bash
mysql -u root -p
```

```SQL
CREATE DATABASE wpdb;
```

```SQL
CREATE USER 'wpdbuser'@'localhost' IDENTIFIED BY 'new_password_here';
```

```sql
GRANT ALL ON wpdb.* TO 'wpdbuser'@'localhost' IDENTIFIED BY 'user_password_here' WITH GRANT OPTION;
```

```SQL
FLUSH PRIVILEGES;
```

```sql
EXIT;
```

### Wordpress

Install Wordpress

```bash
cd /tmp/ && wget http://wordpress.org/latest.tar.gz
```

```bash
tar -xzvf latest.tar.gz
```

```bash
cp -R wordpress/* /var/www/html
```

```bash
rm -rf /var/www/html/*.index.html
```

```bash
cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
```

изменим file-config

```bash
vim /var/www/html/wp-config.php
```

Desired settings:

```php
define( 'DB_NAME', 'wpdb' );
define( 'DB_USER', 'wpdbuser' );
define( 'DB_PASSWORD', 'user_password_here' );
```

Сontinue install

```bash
chown -R www-data:www-data /var/www/html/
```

```bash
chmod -R 755 /var/www/html/
```

```bash
systemctl restart lighttpd.service
```

```bash
ufw allow 80
```

Check: go to http://localhost/
