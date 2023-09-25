FROM ubuntu
# this is the base image

ENV DEBIAN_FRONTEND="noninteractive" \
    PATH=$PATH:/opt/leamp \
    TZ="Asia/Riyadh" 
# ENV is for runtime, so u can use it as variable in the container

RUN apt-get update -y && apt-get upgrade -y && apt-get install -y \
    curl \
    jq \
    ca-certificates \
    apt-transport-https \
    nano \
    unzip \
    wget \
    gnupg \
    cron \
    lsb-release \
    software-properties-common && \
    add-apt-repository ppa:ondrej/php && \
    apt-get update -y && \
    apt install -y \
    dumb-init \
    apache2 \
    mariadb-server \
    mariadb-client \
    php7.4 \
    php7.4-cli \
    php7.4-common \
    php7.4-curl \
    php7.4-gd \
    php7.4-intl \
    php7.4-json \
    php7.4-mbstring \
    php7.4-mysql \
    php7.4-opcache \
    php7.4-readline \
    php7.4-xml \
    php7.4-xsl \
    php7.4-zip \
    php7.4-bz2 \
    libapache2-mod-php7.4 \
    tzdata && \
    cd /usr/share && \
    wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.zip -O phpmyadmin.zip && \
    unzip phpmyadmin.zip && \
    rm phpmyadmin.zip && \
    mv phpMyAdmin-*-all-languages phpmyadmin && \
    chmod -R 0755 phpmyadmin && \
    echo "**** cleanup ****" && \
    apt-get clean && \
    rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/* && \
    mkdir /opt/leamp \
    mkdir /opt/leamp/scripts


COPY scripts/ /opt/leamp/scripts

USER root

WORKDIR /opt/leamp

RUN find /opt/leamp/scripts -type f -exec chmod +x {} \; 


#ENTRYPOINT ["tail", "-f", "/dev/null"] to make running container forever for debugging
ENTRYPOINT ["/opt/leamp/scripts/docker-entrypoint.sh"]
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"] 
# to make apache start automatically