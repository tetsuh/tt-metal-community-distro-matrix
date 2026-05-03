# Dockerfile for Rocky Linux 9.
#
# Unlike Linux Mint, Rocky Linux ships an official upstream container image,
# so we simply layer a minimal bootstrap on top of it instead of impersonating
# the distro from a base Ubuntu image. The bootstrap installs only what
# tt-metal's install_dependencies.sh and tt-installer's install.sh take as a
# precondition (sudo, git, locale data, ca-certificates, procps).
# curl is intentionally omitted: the upstream image ships curl-minimal which
# provides the curl binary; pulling in curl-full conflicts with curl-minimal
# (`package curl-minimal-... conflicts with curl provided by curl-...`).
#
# We pull from quay.io because that is the publisher Rocky Linux operates
# directly. Using ":9" pins to the rolling 9.x tag, matching how the Mint
# Dockerfiles use ":24.04" for Ubuntu — pinning by digest is left for a
# follow-up if reproducibility becomes an issue.
FROM quay.io/rockylinux/rockylinux:9

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Enable EPEL and CRB (CodeReady Builder) before installing the bootstrap
# packages. tt-metal's install_dependencies.sh redhat path (prep_redhat_system)
# requires ninja-build (EPEL) and capstone-devel (CRB) but does not enable
# these repositories itself, so a stock Rocky image fails with
# "Unable to find a match: ninja-build capstone-devel". Enabling EPEL + CRB
# here matches the long-standing convention on RHEL-family systems that any
# non-trivial development workload pulls from these repos, and parallels how
# the Mint Dockerfiles enable the Mint package repository on top of Ubuntu.
#
# We also swap curl-minimal (shipped in the upstream image) for the full
# curl package: tt-metal's install_dependencies.sh installs `curl`
# unconditionally, which conflicts with curl-minimal. Doing the swap once
# here is cheaper than asking install_dependencies.sh to use --allowerasing.
RUN dnf -y install dnf-plugins-core epel-release \
 && dnf config-manager --set-enabled crb \
 && dnf -y swap curl-minimal curl \
 && dnf -y install \
        sudo \
        git \
        ca-certificates \
        glibc-langpack-en \
        procps-ng \
        patch \
 && dnf clean all \
 && rm -rf /var/cache/dnf

CMD ["bash"]
