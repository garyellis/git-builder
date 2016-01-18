#!/bin/bash


# GIT_* and PACKAGE_* vars are overridable
GIT_VERSION=${GIT_VERSION:-2.7.0}
GIT_SRC_PACKAGE=v${GIT_VERSION}.tar.gz
GIT_SRC_DIR=${GIT_SRC_DIR:-git-${GIT_VERSION}}
GIT_INSTALL_PATH=${GIT_INSTALL_PATH:-/usr/local/git}
# GIT_CFLAGS=
PACKAGE_MAINTAINER=${PACKAGE_MAINTAINER:-docker-build@host}
PACKAGE_NAME=${PACKAGE_NAME:-git-static}
PACKAGE_ITERATION=${PACKAGE_ITERATION:-1}
PACKAGE_ARCH=${PACKAGE_ARCH:-x86_64}
PACKAGE_OUT_DIR=${PACKAGE_OUT_DIR:-/data}
# package extension is populated after os is determined
PACKAGE_FILENAME=${PACKAGE_NAME}-${GIT_VERSION}-${PACKAGE_ITERATION}.${PACKAGE_ARCH}

RUBY_VERSION=${RUBY_VERSION:-2.2.1}

# helper functions
bail_on_error(){
# 1=return code, 2=success_message, 3=fail_message
    if [ $1 == 0 ]; then
        if [ ! -z "$2" ]; then
            echo "${2}"

        fi

    else
        if [ ! -z "$3" ]; then
            echo "${3}"
            exit 1

        else
            echo "non zero return on last action. failing"
            exit 1

        fi
    fi
}

apt_update(){
    # update apt cache when it hasn't been updated in last two hours
    two_hours_seconds=7200
    last_two_hours_seconds=$(( $(date +%s) - $two_hours_seconds ))
    if [ $(stat --format=%Y /var/lib/apt/periodic/update-success-stamp ) -le $last_two_hours_seconds ]; then
        echo "    updating apt cache"
        apt-get -q update
        bail_on_error $?
    fi
}

install_git_deps_centos(){
    git_deps_centos=(autoconf \
                     gettext-devel \
                     expat-devel \
                     openssl-devel \
                     openssl-static \
                     libcurl-devel \
                     libssh2-devel \
                     openldap-devel \
                     perl-CPAN \
                     perl-devel \
                     zlib-devel \
                     zlib-static \
                     gcc \
                     glibc-static\
                     e2fsprogs-devel \
                     libidn-devel \
                     krb5-devel \
                     nss \
                     tar)

    echo "    yum -y --quiet groupinstall Development Tools"
    yum -y --quiet groupinstall "Development Tools"
    bail_on_error $? \
                  "    done" \
                  "    failed"

    echo "    yum -y -q install ${git_deps_centos[@]}"
    yum -y --quiet install "${git_deps_centos[@]}"
    bail_on_error $? \
                  "    done" \
                  "    failed"
}

install_git_deps_ubuntu(){
    git_deps_ubuntu=(autoconf \
                     build-essential \
                     libssl-dev \
                     libcurl4-gnutls-dev \
                     libexpat1-dev \
                     gettext)

    apt_update
    echo "    apt-get install -q ${git_deps_ubuntu[@]}"
    apt-get install -qq ${git_deps_ubuntu[@]}
    bail_on_error $? \
                  "    done" \
                  "    failed"
}

install_git_src(){
    curl -L -RO https://github.com/git/git/archive/${GIT_SRC_PACKAGE} &&
    tar xzf $GIT_SRC_PACKAGE &&
    # drop into git src dir
    (
      cd $GIT_SRC_DIR &&

      echo "    make configure 2>&1 >/dev/null"
      make configure 2>&1 >/dev/null
      bail_on_error $?

      #echo     ./configure --prefix=$GIT_INSTALL_PATH CFLAGS="-static $(pkg-config --static --libs libcurl)"
      echo     ./configure --prefix=$GIT_INSTALL_PATH CFLAGS="-static-libgcc" >/dev/null
      ./configure --prefix=$GIT_INSTALL_PATH CFLAGS="-static-libgcc" >/dev/null
      bail_on_error $?

      echo "    make install 2>&1 >/dev/null"
      make install 2>&1 >/dev/null
      bail_on_error $? \
                    "" \
                    "    make install git failed"
    )  

    # cleanup
    #rm -fr $GIT_SRC_DIR $GIT_SRC_PACKAGE
}

verify_git_install(){
    echo "    verifying git binary"
    type $GIT_INSTALL_PATH/bin/git 2>1 >/dev/null &&
    $GIT_INSTALL_PATH/bin/git --version
    bail_on_error $? \
                  "    done" \
                  "    make install git failed"
}

install_ruby_deps_ubuntu(){
    ruby_deps=(autoconf \
               automake \
               build-essential \
               bison \
               libreadline6 \
               libreadline6-dev \
               curl \
               zlib1g-dev \
               libssl-dev \
               libyaml-dev \
               libxml2-dev \
               libc6-dev \
               libtool \
               libgmp-dev \
               gnupg2 \
               ncurses-dev \
               openssl)

    echo "==> installing ruby dependencies"
    echo "    apt-get -qq update"
    apt-get -qq update
    bail_on_error $?

    echo "    apt-get install -qq ${ruby_deps[@]}"
    apt-get install -qq ${ruby_deps[@]}
    bail_on_error $? "    done" "    failed"
}

install_ruby_deps_centos(){
    ruby_deps=(gcc-c++ \
               patch readline \
               readline-devel \
               zlib zlib-devel \
               libyaml-devel \
               libffi-devel \
               openssl-devel \
               make \
               bzip2 \
               autoconf \
               automake \
               libtool \
               bison \
               iconv-devel \
               sqllite-devel \
               which)

    echo "==> installing ruby dependencies"
    echo "    yum -y --quiet install ${ruby_deps[@]}"
    yum -y --quiet install ${ruby_deps[@]}
    bail_on_error $? \
                  "    done" \
                  "    failed"
}

install_ruby(){
    echo "==> installing ruby"
    echo "    curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -"
    curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
    bail_on_error $? \
                  "    gpg key installed" \
                  "    rvm install failed"

    echo "    curl -L get.rvm.io | bash -s stable >/dev/null"
    curl -L get.rvm.io | bash -s stable >/dev/null
    bail_on_error $? \
                  "    done" \
                  "    rvm install failed"

    source /etc/profile.d/rvm.sh

    echo "    rvm install $RUBY_VERSION >/dev/null"
    rvm install $RUBY_VERSION >/dev/null
    bail_on_error $? \
                  "    done" \
                  "    ruby install failed"

    echo "    rvm use $RUBY_VERSION --default >/dev/null"
    rvm use $RUBY_VERSION --default >/dev/null
    ruby --version
}

install_fpm(){
    # install fpm
    echo "==> installing fpm"
    echo "    gem install fpm >/dev/null"
    gem install fpm >/dev/null
    bail_on_error $? \
                  "    done" \
                  "    fpm install failed"

}

# after install and and after remove scripts
git_fpm_after_install_sh(){
  echo "echo export PATH=${GIT_INSTALL_PATH}/bin:\\\$PATH >/etc/profile.d/git.sh" > /tmp/git-after-install.sh
  echo "source /etc/profile.d/git.sh" >> /tmp/git-after-install.sh
  echo "ln -s $GIT_INSTALL_PATH/bin/git /usr/local/bin/git" >> /tmp/git-after-install.sh
  chmod 755 /tmp/git-after-install.sh
}

git_fpm_after_remove_sh(){
  echo "rm /etc/profile.d/git.sh" >> /tmp/git-after-remove.sh
  echo "rm -f /usr/local/bin/git" >> /tmp/git-after-remove.sh
  chmod 755 /tmp/git-after-remove.sh
}




# detect OS distro - configure dependencies installers
if [ -f /etc/centos-release ] || [ -f /etc/redhat-release ]; then
    PACKAGE_TYPE=rpm
    git_deps_installer=install_git_deps_centos
    ruby_deps_installer=install_ruby_deps_centos

elif grep -iq ubuntu /etc/lsb-release || grep -iq ubuntu /etc/os-release ; then
    PACKAGE_TYPE=deb
    git_deps_installer=install_git_deps_ubuntu
    ruby_deps_installer=install_ruby_deps_ubuntu

else
    echo "==> os not supported. failing"
    exit 1

fi


# install git build dependencies and compile git
echo "==> installing git build environment dependencies"
eval $git_deps_installer
echo "==> building git"
install_git_src
verify_git_install


# prepare our fpm installation
echo "==> prepare fpm installation"
eval $ruby_deps_installer
install_ruby
install_fpm

# write our rpm/deb after install and remove scripts
git_fpm_after_install_sh
git_fpm_after_remove_sh


# package our freshly built git binaries

echo "==> creating $PACKAGE_FILENAME"
fpm -n $PACKAGE_NAME \
    -v $GIT_VERSION \
    --iteration $PACKAGE_ITERATION \
    -m $PACKAGE_MAINTAINER \
    -s dir \
    -t $PACKAGE_TYPE \
    --directories $GIT_INSTALL_PATH \
    --after-install /tmp/git-after-install.sh \
    --after-remove /tmp/git-after-remove.sh \
    $GIT_INSTALL_PATH >/dev/null

bail_on_error $? \
              "    done" \
              "    packaging failed. exiting"


echo "==> moving package to configured dest dir: $PACKAGE_OUT_DIR/$PACKAGE_FILENAME"
mkdir -p $PACKAGE_OUT_DIR
# delimeters in filename are different across .deb and .rpm. quick patchup for now
PACKAGE_FILENAME=$(find $PWD -name "*.${PACKAGE_TYPE}")

echo "    mv ${PACKAGE_FILENAME} $PACKAGE_OUT_DIR"
mv ${PACKAGE_FILENAME} $PACKAGE_OUT_DIR
echo "    done"
