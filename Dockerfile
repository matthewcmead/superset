FROM matthewcmead/superset-centos7-base

# Superset version
ARG SUPERSET_VERSION=0.26.3

# Tileserver root url
ARG ARG_TILESERVER_ROOT_URL=localhost:8080
ENV ARG_TILESERVER_ROOT_URL=${ARG_TILESERVER_ROOT_URL}

# Configure environment
ENV LANG=en_US.utf8 \
    LC_ALL=en_US.utf8 \
    PYTHONPATH=/etc/superset:/home/superset:$PYTHONPATH \
    SUPERSET_VERSION=${SUPERSET_VERSION} \
    SUPERSET_HOME=/var/lib/superset

COPY conf/repohost /tmp/repohost

ARG SUPERSET_MD5
ENV SUPERSET_MD5=${SUPERSET_MD5}

RUN \
    export THEHOST=$(cat /tmp/repohost) \
&&  if grep none /tmp/repohost; then export THEHOST=$(ip route show | grep default | sed "s/^default via //; s/ .*$//"); fi \
&&  wget -q http://${THEHOST}:8879/pips/requirements.txt -O /tmp/requirements.txt \
&&  cat /tmp/requirements.txt \
&&  cd /tmp \
&&  wget -q -O - http://${THEHOST}:8879/incubator-superset.tar.gz | tar zxf - \
&&  wget -q -O - http://${THEHOST}:8879/node-v6.11.5-linux-x64.tar.xz | tar -C /usr/local -Jxf - \
&&  export PATH=/usr/local/node-v6.11.5-linux-x64/bin:${PATH} \
&&  cd incubator-superset \
&&  for f in $(find . -type f -print0 | xargs -0 grep -l ARG_TILESERVER_ROOT_URL); do sed -i.bak "s,ARG_TILESERVER_ROOT_URL,${ARG_TILESERVER_ROOT_URL},g" $f; done \
&&  ./pypi_push.sh \
&&  ls -altr dist \
&&  ls -altr /usr/lib/python3.4/site-packages \
&&  pip3.4 uninstall superset || echo "superset not installed" \
&&  pip3.4 install --upgrade --trusted-host ${THEHOST} --no-cache-dir --no-index --find-links http://${THEHOST}:8879/pips/ \
      -r /tmp/requirements.txt \
        dist/superset-0.26.3.tar.gz \
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
        Click==6.7 \
&&  cd /tmp \
&&  rm -rf /usr/local/node-v6.11.5-linux-x64 \
&&  rm -rf /tmp/incubator-superset


#RUN chmod 755 /tini

RUN useradd -b /home -U -m superset && \
    mkdir /etc/superset && \
    mkdir /etc/superset/db && \
    chown -R superset:superset /home/superset /etc/superset

RUN mkdir /var/lib/superset && chown -R superset:superset /var/lib/superset

RUN if [ ! -d /usr/lib/python3.4/site-packages/superset/app ]; then ls /usr/lib/python3.4/site-packages && mkdir /usr/lib/python3.4/site-packages/superset/app; fi \
&&  chown -R superset:superset /usr/lib/python3.4/site-packages/superset/app

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
