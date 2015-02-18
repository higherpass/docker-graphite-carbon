FROM phusion/baseimage
MAINTAINER Higherpass <git@higherpass.com>

ENV DEBIAN_FRONTEND noninteractive

# Install packages
#RUN apt-get update && apt-get install -y python-django-tagging python-simplejson python-cairo python-pysqlite2 python-support python-pip apache2 curl python-dev libapache2-mod-wsgi

RUN apt-get update && apt-get -y -q --force-yes install graphite-web graphite-carbon apache2 libapache2-mod-wsgi apache2-utils

# Install Carbon and Graphite
#RUN pip install Twisted==11.1.0
#RUN pip install Django==1.5
#RUN pip install --install-option="--prefix=/var/lib/graphite" \
#                --install-option="--install-lib=/var/lib/graphite/webapp" \
#                graphite-web==0.9.12

RUN graphite-manage syncdb --noinput

# Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Startup scripts based on phusion/baseimage
# Apache
RUN mkdir /etc/service/apache2
ADD ./scripts/apache2 /etc/service/apache2/run
RUN chmod +x /etc/service/apache2/run
# Carbon
RUN mkdir /etc/service/carbon-cache
ADD ./scripts/carbon-cache /etc/service/carbon-cache/run
RUN chmod +x /etc/service/carbon-cache/run

# Configure Graphite/Carbon Storage
RUN mkdir -p /var/lib/graphite/storage/log/webapp
RUN chown -R www-data /var/lib/graphite/storage/log/webapp

# Setup Apache
RUN mkdir /etc/apache2/wsgi
RUN a2dissite 000-default
ADD ./graphite/apache2-graphite.conf /etc/apache2/sites-available/apache2-graphite.conf
RUN a2ensite apache2-graphite

# Setup Graphite
RUN chown www-data:www-data /var/log/graphite
RUN chgrp www-data /var/lib/graphite
RUN chmod g+w /var/lib/graphite
RUN touch /var/lib/graphite/graphite.db
RUN chown www-data:www-data /var/lib/graphite/graphite.db
RUN echo 'chown www-data:www-data ${INDEX_FILE}' >> /usr/bin/graphite-build-search-index

# Allow external connections
EXPOSE 80 2003
CMD ["/sbin/my_init"]
