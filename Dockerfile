FROM matthewcmead/anaconda-nb-docker-centos7 as builder

# Superset version
ARG SUPERSET_VERSION=0.18.5

# Configure environment
ENV LANG=en_US.utf8 \
    LC_ALL=en_US.utf8 \
    PATH=$PATH:/home/superset/.bin \
    PYTHONPATH=/home/superset/.superset:$PYTHONPATH \
    SUPERSET_VERSION=${SUPERSET_VERSION}

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
&&  pip install --find-links /project/pips \
        flask-mail==0.9.1 \
        flask-oauth==0.12 \
        flask_oauthlib==0.9.3 \
        impyla==0.14.0 \
        mysqlclient==1.3.7 \
        psycopg2==2.6.1 \
        pyhive==0.2.1 \
        pyldap==2.4.28 \
        redis==2.10.5 \
        sqlalchemy-redshift==0.5.0 \
        sqlalchemy-clickhouse==0.1.1.post3 \
        superset==$SUPERSET_VERSION

RUN  mkdir /conda_overlay \
&&   tar -C /opt -cf - $(cd /opt && find conda -type f -newer /tmp/install_timestamp ) | (cd /conda_overlay && tar xf -)

FROM matthewcmead/anaconda-nb-docker-centos7 as runner

# Superset version
ARG SUPERSET_VERSION=0.18.5

# Configure environment
ENV LANG=en_US.utf8 \
    LC_ALL=en_US.utf8 \
    PATH=$PATH:/home/superset/.bin \
    PYTHONPATH=/home/superset/.superset:$PYTHONPATH \
    SUPERSET_VERSION=${SUPERSET_VERSION}

RUN yum install -y \
      cyrus-sasl-devel \
      openldap-devel \
      mariadb-devel \
      postgresql-devel \
&&  yum clean all

COPY --from=builder /conda_overlay/conda /opt/conda

RUN useradd -b /home -U -m superset && \
    mkdir /home/superset/.superset && \
    touch /home/superset/.superset/superset.db && \
    chown -R superset:superset /home/superset

# Configure Filesysten
WORKDIR /home/superset
COPY superset .
VOLUME /home/superset/.superset

# Deploy application
EXPOSE 8088
HEALTHCHECK CMD ["curl", "-f", "http://localhost:8088/health"]
ENTRYPOINT ["superset"]
CMD ["runserver"]
USER superset


