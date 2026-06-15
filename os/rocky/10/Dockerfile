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
#
# The curl swap is guarded by `rpm -q curl-minimal`: newer Rocky 10 base
# images already ship the full `curl` package, in which case
# `dnf swap curl-minimal curl` aborts with a conflict. The guard makes the
# swap a no-op when full curl is already present (and keeps working on
# images that still ship curl-minimal, e.g. Rocky 9).
RUN dnf -y install dnf-plugins-core epel-release \
 && dnf config-manager --set-enabled crb \
 && if rpm -q curl-minimal >/dev/null 2>&1; then dnf -y swap curl-minimal curl; fi \
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
