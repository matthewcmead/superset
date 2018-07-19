#!/usr/bin/env bash

set -e

sed -i "s/override_install_langs=en_US.UTF-8/override_install_langs=en_US.utf8/g" /etc/yum.conf 
yum groups mark install "Development Tools"
yum groups mark convert "Development Tools"
yum groupinstall -y 'Development Tools'
yum install -y mariadb-devel postgresql epel-release
yum install -y python34 python34-pip python34-devel python34-Cython
cd /project/pips
export SUPERSET_VERSION=0.26.3
export SUPERSET_REPO=apache/incubator-superset
curl https://raw.githubusercontent.com/${SUPERSET_REPO}/${SUPERSET_VERSION}/requirements.txt -o requirements.txt
	pip3  download \
        --no-cache-dir \
        -r requirements.txt \
        Werkzeug==0.12.1 \
        flask-cors==3.0.3 \
        flask-mail==0.9.1 \
        flask-oauth==0.12 \
        flask_oauthlib==0.9.3 \
        gevent==1.2.2 \
        impyla==0.14.0 \
        mysqlclient==1.3.7 \
        psycopg2==2.6.1 \
        pyathena==1.2.5 \
        pyhive==0.5.1 \
        pyldap==2.4.28 \
        redis==2.10.5 \
        msgpack \
        superset==${SUPERSET_VERSION}

