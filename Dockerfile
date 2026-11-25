FROM php:8.5-cli-alpine3.24

ADD config/crontab /crontab
COPY config/entry.sh /entry.sh
COPY config/backup-database.sh /backup/database.sh
COPY config/backup-directory.sh /backup/directory.sh
COPY config/mariadb-client.cnf /etc/my.cnf.d/zz-docker-env-backup.cnf

RUN chmod 755 /entry.sh /backup/database.sh /backup/directory.sh && \
    /usr/bin/crontab /crontab && \
    # Install: dependencies
    #   mariadb-client provides mysqldump; s3cmd (community) pulls in python3
    #   mariadb-connector-c provides the caching_sha2_password auth plugin,
    #   the only login method MySQL 8.4 enables by default
    apk upgrade --no-cache && \
    apk add --no-cache \
        bash \
        git \
        libzip \
        mariadb-client \
        mariadb-connector-c \
        s3cmd \
        unzip \
        zip && \
    # Install: PHP extensions (zip is required by the Shed CLI)
    apk add --no-cache --virtual .build-deps libzip-dev && \
    docker-php-ext-install zip && \
    apk del .build-deps && \
    # Install: Shed Command Line Tool
    git clone --depth 1 https://github.com/shedcollective/shed-cli-tool.git $HOME/shed-cli-tool && \
    ln -s $HOME/shed-cli-tool/dist/shed /usr/local/bin/shed && \
    # Sanity check: everything the backup commands call is present
    php -m | grep -qx zip && \
    command -v mysqldump && \
    find /usr/lib -name caching_sha2_password.so | grep -q . && \
    command -v s3cmd && \
    command -v tar && \
    shed --version

CMD ["/entry.sh"]
