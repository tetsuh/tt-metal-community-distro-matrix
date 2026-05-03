# Dockerfile for Rocky Linux 10.
#
# See os/rocky/9/Dockerfile for the rationale behind the thin-bootstrap
# approach (Rocky publishes an official image, so we do not need to
# impersonate the distro from a base Ubuntu image).
FROM quay.io/rockylinux/rockylinux:10

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

RUN dnf -y install \
        sudo \
        git \
        curl \
        ca-certificates \
        glibc-langpack-en \
        procps-ng \
 && dnf clean all \
 && rm -rf /var/cache/dnf

CMD ["bash"]
