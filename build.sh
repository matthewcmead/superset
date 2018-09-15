#!/usr/bin/env bash

function usage {
  echo "Usage: $0 <host:port for tileserver-gl URL> [-skippipdl]"
}

function bail {
  echo "$1"
  kill_server
  exit 1
}

if [ $# != 1 -a $# != 2 ]; then
  usage
  exit 1
fi

if [ $# == 2 -a "$2" != "-skippipdl" ]; then
  usage
  exit 1
fi

if [ ! -z $2 ]; then
  SKIP_DL=1
else
  SKIP_DL=0
fi

trap kill_server INT

function kill_server {
  kill -9 %1
}

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  TARGET="$(readlink "$SOURCE")"
  if [[ $TARGET == /* ]]; then
    SOURCE="$TARGET"
  else
    DIR="$( dirname "$SOURCE" )"
    SOURCE="$DIR/$TARGET" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  fi
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

if [ $(uname) == "Darwin" ]; then
  echo docker.for.mac.localhost >conf/repohost
else
  echo none >conf/repohost
fi

if python --version 2>&1 | grep '^Python 3' >/dev/null; then
  python_http_server="http.server"
elif python --version 2>&1 | grep '^Python 2' >/dev/null; then
  python_http_server="SimpleHTTPServer"
else
  echo "Can't detect python version.  Please ensure python 2 or python 3 is installed and rerun this build script."
  exit 1
fi

python -m "$python_http_server" 8879 &

cd "$DIR" && \
docker run -it --rm -e ARG_TILESERVER_ROOT_URL="$1" -e SKIP_DL="$SKIP_DL" -v $(pwd):/project centos:7 /project/getpips.sh || bail "Failed to get dependencies and/or modify for tileserver URL"
docker build -t matthewcmead/superset-centos7 . || bail "Failed to build final container."
kill_server
