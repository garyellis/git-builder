#!/bin/bash


distro=centos
distro_version=6
# docker hub repo
username=garyellis
name=git-rpm
version=0.1



docker pull ${distribution}:${version}

docker build --rm=true \
             --file=Dockerfile.${distro}-${distro_version} \
             --tag=${username}/${name}:${version} \
             $PWD


#docker push ${username}/${name}:${version}

docker run -d -e GIT_VERSION=2.6.0 ${username}/${name}:${version}
