#!/usr/bin/env bash

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

python -m SimpleHTTPServer 8879 &
cd "$DIR" && \
#docker run -it --rm -v $(pwd):/project matthewcmead/anaconda-nb-docker-centos7 /project/getpips.sh
docker build -t matthewcmead/superset-centos7 .
kill_server
