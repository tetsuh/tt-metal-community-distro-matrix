# Dockerfile for Rocky Linux 10.
#
# See os/rocky/9/Dockerfile for the rationale behind the thin-bootstrap
# approach (Rocky publishes an official image, so we do not need to
# impersonate the distro from a base Ubuntu image).
FROM quay.io/rockylinux/rockylinux:10

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Enable EPEL and CRB before installing the bootstrap packages —
# see os/rocky/9/Dockerfile for the rationale (tt-metal's
# install_dependencies.sh requires ninja-build / capstone-devel which
# live in EPEL / CRB respectively, and the script does not enable
# those repositories itself).
#
# curl is intentionally omitted: the upstream image ships curl-minimal
# which provides the curl binary; installing curl-full would conflict.
RUN dnf -y install dnf-plugins-core epel-release \
 && dnf config-manager --set-enabled crb \
 && dnf -y install \
        sudo \
        git \
        ca-certificates \
        glibc-langpack-en \
        procps-ng \
 && dnf clean all \
 && rm -rf /var/cache/dnf

CMD ["bash"]
