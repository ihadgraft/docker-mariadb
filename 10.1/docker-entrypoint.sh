#!/bin/sh

function f_mysql_grant {
    local user="$1"
    local pass="$2"
    local db="$3"
    local privs="$4"

    echo "GRANT ${privs} ON ${db}.* TO '${user}'@'%' IDENTIFIED BY '${pass}';" | mysql -u root -p"$MYSQL_ROOT_PASSWORD"
}

if [ $(find /var/lib/mysql -mindepth 1 | wc -l) -eq 0 ] ; then
    mysql_install_db --user=mysql
fi

chown -R mysql:mysql /var/lib/mysql

mysqld_safe --skip-grant-tables &

while [ ! -e /run/mysqld/mysqld.sock ] ; do
    echo "Waiting for mysqld to start..."
    sleep 1
done

if [ -z "$MYSQL_ROOT_PASSWORD" ] ; then
    export MYSQL_ROOT_PASSWORD=$(pwgen -s 24 1)
fi

expect -f - << EOF
    set timeout 5
    spawn mysql_secure_installation
    expect "Enter current password for root (enter for none):"
    send -- "\r"
    expect "Set root password?"
    send -- "y\r"
    expect "New password:"
    send -- "${MYSQL_ROOT_PASSWORD}\r"
    expect "Re-enter new password:"
    send -- "${MYSQL_ROOT_PASSWORD}\r"
    expect "Remove anonymous users?"
    send -- "y\r"
    expect "Disallow root login remotely?"
    send -- "y\r"
    expect "Remove test database and access to it?"
    send -- "y\r"
    expect "Reload privilege tables now?"
    send -- "y\r"
    expect eof
EOF

if ! mysql -u root -p"$MYSQL_ROOT_PASSWORD" -Bse 'SHOW DATABASES' | grep -q ^${DATABASE_NAME}$ ; then
    mysqladmin -u root -p"$MYSQL_ROOT_PASSWORD" create "$DATABASE_NAME"
fi

if [ -z "$APP_PASSWORD" ] ; then
    export APP_PASSWORD=$(pwgen -s 24 1)
fi
f_mysql_grant "$APP_USER" "$APP_PASSWORD" "$DATABASE_NAME" "$APP_PRIVILEGES"

echo 'FLUSH PRIVILEGES;' | mysql -u root -p"$MYSQL_ROOT_PASSWORD"

mysqladmin -u root -p"$MYSQL_ROOT_PASSWORD" shutdown

"$@"
