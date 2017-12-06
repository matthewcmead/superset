FROM matthewcmead/anaconda-nb-docker-centos7 as builder

# Superset version
ARG SUPERSET_VERSION=0.20.6

# Configure environment
ENV LANG=en_US.utf8 \
    LC_ALL=en_US.utf8 \
    PYTHONPATH=/etc/superset:$PYTHONPATH \
    SUPERSET_VERSION=${SUPERSET_VERSION} \
    SUPERSET_HOME=/home/superset

COPY pips /project/pips

RUN \
    touch /tmp/install_timestamp \
&&  sed -i "s/override_install_langs=en_US.UTF-8/override_install_langs=en_US.utf8/g" /etc/yum.conf \
&&  yum groups mark install "Development Tools" \
&&  yum groups mark convert "Development Tools" \
&&  yum groupinstall -y 'Development Tools' \
&&  yum install -y \
      cyrus-sasl-devel \
      openldap-devel \
      mariadb-devel \
      postgresql-devel \
      libffi-devel \
&&  pip install --no-index --find-links /project/pips \
        flask-cors==3.0.3 \
        flask-mail==0.9.1 \
        flask-oauth==0.12 \
        flask_oauthlib==0.9.3 \
        gevent==1.2.2 \
        impyla==0.14.0 \
        mysqlclient==1.3.7 \
        psycopg2==2.6.1 \
        pyhive==0.5.0 \
        pyldap==2.4.28 \
        redis==2.10.5 \
        sqlalchemy-redshift==0.5.0 \
        sqlalchemy-clickhouse==0.1.1.post3 \
        Werkzeug==0.12.1 \
        superset==${SUPERSET_VERSION}

RUN  mkdir /conda_overlay \
&&   (cd /opt && find conda -type f -newer /tmp/install_timestamp >/tmp/conda_changed.txt) \
&&   tar -C /opt --files-from /tmp/conda_changed.txt -cf - | tar -C /conda_overlay -xf -

FROM matthewcmead/anaconda-nb-docker-centos7 as runner

# Superset version
ARG SUPERSET_VERSION=0.20.6

# Configure environment
ENV LANG=en_US.utf8 \
    LC_ALL=en_US.utf8 \
    PYTHONPATH=/etc/superset:$PYTHONPATH \
    SUPERSET_VERSION=${SUPERSET_VERSION} \
    SUPERSET_HOME=/home/superset

RUN yum install -y \
      cyrus-sasl-devel \
      openldap-devel \
      mariadb-devel \
      postgresql-devel \
      libffi-devel \
&&  yum clean all

COPY --from=builder /conda_overlay/conda /opt/conda

RUN useradd -b /home -U -m superset && \
    mkdir /etc/superset && \
    chown -R superset:superset /home/superset /etc/superset

# Configure Filesysten
COPY superset /usr/local/bin
VOLUME /etc/superset
WORKDIR /home/superset

# Deploy application
EXPOSE 8088
HEALTHCHECK CMD ["curl", "-f", "http://localhost:8088/health"]
ENTRYPOINT ["superset"]
CMD ["runserver"]
USER superset


