#!/bin/bash


distro=ubuntu
distro_version=14.04
# docker hub repo
username=garyellis
name=git-deb
version=0.1



#docker pull ${distribution}:${version}

docker build --rm=true \
             --file=Dockerfile.${distro}-${distro_version} \
             --tag=${username}/${name}:${version} \
             $PWD


#docker push ${username}/${name}:${version}


GIT_VERSION=${GIT_VERSION:-2.7.0}

echo docker run -d -e GIT_VERSION=$GIT_VERSION -v $PWD:/data ${username}/${name}:${version}
docker run -d -e GIT_VERSION=$GIT_VERSION -v $PWD:/data ${username}/${name}:${version}
