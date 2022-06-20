FROM php:8.1.7-cli-alpine3.16

ADD config/crontab /crontab
COPY config/entry.sh /entry.sh
COPY config/backup-database.sh /backup/database.sh
COPY config/backup-directory.sh /backup/directory.sh

RUN chmod 755 /entry.sh /backup/database.sh /backup/directory.sh && \
    /usr/bin/crontab /crontab && \
    # Install: dependencies
    apk upgrade && \
    apk add \
        bash \
        git \
        zip \
        unzip \
        zlib-dev \
        libzip-dev \
        php-zip \
        mysql-client \
        python3 \
        py-pip && \
    # Ensure `python3` is available as simply `python`
    ln -s /usr/bin/python3 /usr/bin/python && \
    # Install: PHP extensions
    docker-php-ext-install \
        zip && \
    # Install: Shed Command Line Tool
    git clone https://github.com/shedcollective/shed-cli-tool.git $HOME/shed-cli-tool && \
    ln -s $HOME/shed-cli-tool/dist/shed /usr/local/bin/shed && \
    # Install: s3cmd
    pip install python-dateutil && \
    mkdir -p $HOME/s3cmd && \
    cd $HOME/s3cmd && \
    wget https://github.com/s3tools/s3cmd/releases/download/v2.2.0/s3cmd-2.2.0.tar.gz && \
    tar -xzf s3cmd-2.2.0.tar.gz && \
    cd s3cmd-2.2.0 && \
    python3 setup.py install && \
    ln -s $HOME/s3cmd/s3cmd-2.2.0/s3cmd /usr/local/bin/s3cmd

CMD ["/entry.sh"]
