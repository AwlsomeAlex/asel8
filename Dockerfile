# syntax=docker/dockerfile:1

# Copyright (C) 2023-2024 Alexander Barris
# GNU GPLv3 - All Rights Reserved

# Dockerfile that will build an image with mock and
# rpmdevtools installed and configred. Then used with
# ascelr8.sh to grab, patch and build the latest
# kernel.src.rpm

# I chose AlmaLinux as a base since Red Hat's UBI repos
# don't contain every dependency needed by mock.

FROM    almalinux:8
LABEL   com.awlsome.version="0.0.1"
LABEL   description="AlmaLinux 8 image designed to compile EL8 kernels"
LABEL   vendor="AwlsomeAlex"
SHELL   ["/bin/bash", "-c"]
WORKDIR /root
WORKDIR rpmbuild
RUN <<EOT bash
    set -ex
    dnf install -y 'dnf-command(config-manager)'
    dnf config-manager --set-enabled powertools
    dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    dnf install -y rpmdevtools mock
    rpmdev-setuptree
    usermod -a -G mock root
    echo '%_topdir %(echo $HOME)/rpmbuild' > ~/.rpmmacros
    dnf clean all
    rm -rf /var/cache/dnf
EOT
COPY ascelr8.sh /root/rpmbuild/
COPY ascelr8-aarch64.cfg /etc/mock/site-defaults.cfg
