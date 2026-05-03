# Dockerfile for Debian 13 "trixie".
#
# Same policy as os/debian/12/Dockerfile: layer a minimal bootstrap on top
# of the official `debian:13` image. Two patches to tt-metal's
# install_dependencies.sh are applied at runtime by the workflow; see the
# header comment in os/debian/12/Dockerfile and os/debian/README.md for
# rationale.
FROM debian:13

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANGUAGE=en_US:en

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        wget \
        gnupg \
        gpg \
        jq \
        git \
        sudo \
        locales \
        lsb-release \
 && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
 && locale-gen en_US.UTF-8 \
 && rm -rf /var/lib/apt/lists/*

CMD ["bash"]
