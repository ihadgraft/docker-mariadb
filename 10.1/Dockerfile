FROM alpine:edge

RUN apk update \
  && apk add mysql \
  && apk add mysql-client \
  && apk add pwgen \
  && apk add expect \
  && rm -rf /var/cache/apk/*

RUN mkdir -p /run/mysqld
RUN chown mysql:mysql /run/mysqld

ENV MYSQL_ROOT_PASSWORD ""
ENV APP_USER "app"
ENV APP_PASSWORD ""
ENV APP_PRIVILEGES "ALL"
ENV DATABASE_NAME "app"


ADD docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["mysqld_safe", "--user", "mysql"]
