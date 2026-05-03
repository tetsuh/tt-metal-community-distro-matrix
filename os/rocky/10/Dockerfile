# Dockerfile for Rocky Linux 10.
#
# See os/rocky/9/Dockerfile for the rationale behind the thin-bootstrap
# approach (Rocky publishes an official image, so we do not need to
# impersonate the distro from a base Ubuntu image).
FROM quay.io/rockylinux/rockylinux:10

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    PATH=/usr/lib64/openmpi/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    PKG_CONFIG_PATH=/usr/lib64/openmpi/lib/pkgconfig \
    LD_LIBRARY_PATH=/usr/lib64/openmpi/lib

# See os/rocky/9/Dockerfile for the rationale behind every choice here:
#  * EPEL + CRB are required for ninja-build / capstone-devel
#  * curl-minimal must be swapped for full curl
#  * patch / file / zlib-devel cover gaps in tt-metal prep_redhat_system
#  * MPI environment variables expose the openmpi install under
#    /usr/lib64/openmpi/ to pkg-config / runtime loaders.
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
        file \
        zlib-devel \
 && dnf clean all \
 && rm -rf /var/cache/dnf

CMD ["bash"]
