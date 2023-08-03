# Multistage docker file 
# In the BUILD stage we 
# - get the main application with git
# - build all the required extensions
# In the final stage we 
# - copy the pre-build extensions

# syntax = docker/dockerfile:1.2
FROM php:8.0-apache-bullseye AS BUILD
LABEL AUTHOR Lucrasoft
WORKDIR /home

RUN --mount=type=secret,id=mysecret,dst=/var/secret/mysecret \ 
    apt-get update \
    && apt-get install git -y \
    && cat /var/secret/mysecret > ~/.git-credentials \
    && git config --system credential.helper store \
    && git clone https://passwork.download/passwork/passwork.git tmp \
    && cd /home/tmp \
    && git checkout v5 \
    && cd /home

RUN pecl install mongodb \
    && pecl install psr \
    && pecl install phalcon-5.0.0beta3

RUN docker-php-ext-install bcmath

#the ldap extensions requires ldap headers to be available.
RUN apt-get install -y libldb-dev libldap2-dev 
RUN docker-php-ext-install ldap

#clean up the git files so we don't copy them into the final image
RUN rm -r -f /home/tmp/.git

#final build
FROM php:8.0-apache-bullseye

#
RUN apt-get update \
    && apt-get install cron -y

# copy the builded extensions
COPY --from=BUILD /usr/local/lib/php/extensions/no-debug-non-zts-20200930/ /usr/local/lib/php/extensions/no-debug-non-zts-20200930/
#
RUN echo "extension=mongodb.so" | tee /usr/local/etc/php/conf.d/20-mongodb.ini \
    && echo "extension=psr.so" | tee /usr/local/etc/php/conf.d/20-psr.ini \
    && echo "extension=phalcon.so" | tee /usr/local/etc/php/conf.d/30-phalcon.ini \
    && echo "extension=bcmath.so" | tee /usr/local/etc/php/conf.d/40-bcmath.ini \
    && echo "extension=ldap.so" | tee /usr/local/etc/php/conf.d/50-ldap.ini

COPY --from=BUILD /home/tmp/ /var/www/

RUN find /var/www/ -type d -exec chmod 755 {} \; 
RUN find /var/www/ -type f -exec chmod 644 {} \; 
RUN chown -R www-data:www-data /var/www/

COPY default.conf /etc/apache2/sites-enabled/000-default.conf

# setup background tasks with cron
RUN echo '* * * * * bash -l -c "php /var/www/app/tools/run-scheduled-tasks.php"' > /etc/mycron
RUN crontab -u root /etc/mycron

RUN a2enmod rewrite
# clean up pecl compiles
RUN apt-get clean 
RUN rm -f -r /tmp/*

# a new entrypoint which also starts cron
COPY entrypoint /usr/local/bin/
RUN chmod 775 /usr/local/bin/entrypoint
ENTRYPOINT ["entrypoint"]

CMD ["apache2-foreground"]
