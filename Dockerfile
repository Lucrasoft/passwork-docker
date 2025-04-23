FROM ubuntu:jammy-20250404

LABEL AUTHOR="Lucrasoft"

ARG SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.29/supercronic-linux-amd64
ARG SUPERCRONIC_SHA1SUM=cd48d45c4b10f3f0bfdd3a57d054cd05ac96812b
ARG GOSU_VERSION=1.17

ENV DEBIAN_FRONTEND=noninteractive
ENV INIT_DIR="/server/init/"
ENV FILES_DIR="/server/"

# NGINX part
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
       nginx 

RUN mkdir -p /server/nginx /server/nginx/extra /server/nginx-default /server/ssl /server/log/nginx /server/init

# instead of placing the files in nginx-default , we place them in nginx directly 
COPY conf/nginx.conf /server/nginx/nginx.conf
#COPY conf/nginx.conf.v6 /server/nginx-default/default.conf.old
COPY conf/extra /server/nginx/extra

RUN mkdir -p /var/cache/nginx /var/lib/nginx /var/lib/nginx/body /var/log/nginx \ 
    && chown -R 1001:1001 /var/cache/nginx /var/lib/nginx /var/log/nginx 

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
       software-properties-common unzip ssmtp gnupg curl libldap-common 
       
    
RUN gpg --keyserver keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C \
  && gpg --export --armor 4F4EA0AAE5267A6C | apt-key add - \
  && echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu jammy main" > /etc/apt/sources.list.d/ondrej-php.list

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
       php8.3-fpm php8.3-cli php8.3-dev php8.3-ldap php8.3-xml \
       php8.3-bcmath php8.3-mbstring php8.3-mongodb php8.3-curl \
       php8.3-opcache php8.3-readline php8.3-zip php8.3-intl rsyslog \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN useradd -u 1001 -r -s /usr/sbin/nologin app_user
RUN mkdir -p /server/logs /server/php /server/php-default /server/log/php /server/www /run/php /licenses/gosu /licenses/supercronic 

RUN curl -fsSLO https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64 \
    && curl -fsSLO https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64.asc \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify gosu-amd64.asc gosu-amd64 \
    && rm -rf "$GNUPGHOME" gosu-amd64.asc \
    && chmod +x gosu-amd64 \
    && mv gosu-amd64 /usr/local/bin/gosu \
    && curl -fsSL -o /licenses/gosu/LICENSE https://raw.githubusercontent.com/tianon/gosu/${GOSU_VERSION}/LICENSE

RUN curl -fsSLO "$SUPERCRONIC_URL" \
  && echo "${SUPERCRONIC_SHA1SUM}  supercronic-linux-amd64" | sha1sum -c - \
  && chmod +x supercronic-linux-amd64 \
  && mv supercronic-linux-amd64 /usr/local/bin/supercronic \
  && curl -fsSL -o /licenses/supercronic/LICENSE https://raw.githubusercontent.com/aptible/supercronic/master/LICENSE.md


RUN rm -rf /etc/php/8.3/cli/php.ini \
  && rm -rf /etc/php/8.3/fpm/php.ini \
  && rm -rf /etc/php/8.3/fpm/php-fpm.conf \
  && ln -s /server/php/cli-php.ini /etc/php/8.3/cli/php.ini \
  && ln -s /server/php/fpm-php.ini /etc/php/8.3/fpm/php.ini \
  && ln -s /server/php/www.pool /etc/php/8.3/fpm/www.conf \
  && ln -s /server/php/php-fpm.conf /etc/php/8.3/fpm/php-fpm.conf \
  && sed -i 's/mailhub=mail/mailhub=postfix/g' '/etc/ssmtp/ssmtp.conf' \
  && sed -i 's/#FromLineOverride=YES/FromLineOverride=YES/g' '/etc/ssmtp/ssmtp.conf' \
  && cp /etc/ldap/ldap.conf /server/php-default/ldap.conf \
  && rm -rf /etc/ldap/ldap.conf \
  && ln -s /server/php/ldap.conf /etc/ldap/ldap.conf \
  && rm -rf /etc/rsyslog.conf \
  && ln -s /server/php/rsyslog.conf /etc/rsyslog.conf

COPY conf/* /server/php/
COPY conf/* /server/php-default/
COPY entrypoint.sh /entrypoint.sh

# Copy the latest version of passwork
COPY /tmp/passwork/* /server/www/
RUN find /server/www/ -type d -exec chmod 755 {} \; \
    && find /server/www/ -type f -exec chmod 644 {} \; \
    && chown -R 1001:1001 /server/www/


ENTRYPOINT ["/entrypoint.sh"]
CMD ["supercronic", "/server/schedule"]
