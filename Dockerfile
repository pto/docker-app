FROM debian:jessie
MAINTAINER Peter Olsen "polsen@gannett.com"

ENV APT_GET_UPDATED "2014-10-06"
RUN apt-get update && apt-get -y upgrade

RUN apt-get -y install alien aptitude build-essential man nodejs vim wget \
	libcurl4-openssl-dev libgdbm-dev libffi-dev libreadline-dev \
	libssl-dev zlib1g-dev \
	apache2-dev apache2-mpm-worker

RUN apt-get -y install unixODBC-dev
COPY config/ibm-iaccess-1.1.0.1-1.0.x86_64.rpm /
RUN alien -i --scripts ibm-iaccess-1.1.0.1-1.0.x86_64.rpm

RUN wget http://cache.ruby-lang.org/pub/ruby/2.1/ruby-2.1.3.tar.gz \
	&& tar xfz ruby-2.1.3.tar.gz \
	&& cd ruby-2.1.3 \
	&& ./configure \
	&& make install

RUN mkdir /var/lock/apache2
RUN chown www-data.root /var/lock/apache2

RUN gem install --no-rdoc --no-ri passenger bundler \
	&& passenger-install-apache2-module --auto --languages ruby

RUN gem sources --add http://gems.gcinmass.com

COPY app/ /opt/app/
RUN chown -R www-data /opt/app

RUN gem install -v='0.6.6' ibm_db_odbc
RUN cd /opt/app && bundle install
COPY config/mods-enabled/ /etc/apache2/mods-enabled/
COPY config/sites-enabled/ /etc/apache2/sites-enabled/
RUN rm -f /etc/apache2/sites-enabled/000-default.conf

CMD ["apachectl", "-D", "FOREGROUND"]
EXPOSE 80

ENV SECRET_KEY_BASE 1da74decd6c6daa8785d6670481e425cb4a2602d020acbdab2c1d586631a00ac181aa89953ce53799a78d870d3c981b48a6977aa918a96defe2e8231de1172d0

COPY config/odbc.ini /etc/odbc.ini
RUN ln -s libodbcinst.so.2.0.0 /usr/lib64/libodbcinst.so.1
COPY config/iSeriesAccess.conf /etc/ld.so.conf.d/
RUN ldconfig
