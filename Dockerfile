FROM centos:7

# Superset version
ARG SUPERSET_VERSION=0.26.3

# Configure environment
ENV LANG=en_US.utf8 \
    LC_ALL=en_US.utf8 \
    PYTHONPATH=/etc/superset:/home/superset:$PYTHONPATH \
    SUPERSET_VERSION=${SUPERSET_VERSION} \
    SUPERSET_HOME=/var/lib/superset

RUN \
    sed -i "s/override_install_langs=en_US.UTF-8/override_install_langs=en_US.utf8/g" /etc/yum.conf \
&&  yum groups mark install "Development Tools" \
&&  yum groups mark convert "Development Tools" \
&&  yum groupinstall -y 'Development Tools' \
&&  yum install -y \
      wget \
      bzip2 \
      ca-certificates \
      glib2 \
      libXext \
      libSM \
      libXrender \
      git \
      mercurial \
      subversion \
      curl \
      grep \
      sed \
      cyrus-sasl-devel \
      openldap-devel \
      mariadb-devel \
      postgresql-devel \
      libffi-devel \
      cyrus-sasl-devel \
      openldap-devel \
      mariadb-devel \
      postgresql-devel \
      libffi-devel \
&&  yum install -y epel-release \
&&  yum install -y python34 python34-pip python34-devel python34-Cython \
&&  yum clean all

COPY conf/repohost /tmp/repohost

RUN \
    export THEHOST=$(cat /tmp/repohost) \
&&  if grep none /tmp/repohost; then export THEHOST=$(ip route show | grep default | sed "s/^default via //; s/ .*$//"); fi \
&&  wget http://${THEHOST}:8879/pips/requirements.txt -O /tmp/requirements.txt \
&&  cat /tmp/requirements.txt \
&&  pip3.4 install --trusted-host ${THEHOST} --no-cache-dir --no-index --find-links http://${THEHOST}:8879/pips/ \
      -r /tmp/requirements.txt \
        Werkzeug==0.12.1 \
        flask-cors==3.0.3 \
        flask-mail==0.9.1 \
        flask-oauth==0.12 \
        flask_oauthlib==0.9.3 \
        gevent==1.2.2 \
        impyla==0.14.0 \
        mysqlclient==1.3.7 \
        psycopg2==2.6.1 \
        pyhive==0.5.1 \
        pyldap==2.4.28 \
        redis==2.10.5 \
        superset==${SUPERSET_VERSION}


#RUN chmod 755 /tini

RUN useradd -b /home -U -m superset && \
    mkdir /etc/superset && \
    mkdir /etc/superset/db && \
    chown -R superset:superset /home/superset /etc/superset

RUN mkdir /var/lib/superset && chown -R superset:superset /var/lib/superset

# Configure Filesystem
COPY superset /usr/local/bin
VOLUME /var/lib/superset
WORKDIR /home/superset

COPY bin/tini /tini

# Deploy application
EXPOSE 8088
HEALTHCHECK CMD ["curl", "-f", "http://localhost:8088/health"]
ENTRYPOINT [ "/tini", "--" ]
CMD ["/usr/local/bin/superset-start"]
USER superset
