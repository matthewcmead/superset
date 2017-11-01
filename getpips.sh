#!/usr/bin/env bash

yum install -y mariadb-devel postgresql
cd /project/pips
export SUPERSET_VERSION=0.20.4
	pip download \
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
        infi.clickhouse_orm==0.9.8 \
        iso8601==0.1.12 \
        Werkzeug==0.12.1 \
        requests==2.17.3 \
        urllib3==1.21.1 \
        superset==$SUPERSET_VERSION
