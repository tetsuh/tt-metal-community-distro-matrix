# Dockerfile for Ubuntu 26.04 LTS "Resolute Wombat".
#
# Used by build-tt-metal.yaml as a *next-LTS canary*: the Tenstorrent apt
# repository (ppa.tenstorrent.com) does not yet publish a `resolute`
# pocket, so the upstream installer fails on vanilla Ubuntu 26.04. With
# the patches under patches/ubuntu/installer/ we map the codename onto
# `noble` (24.04) so the install completes and the build phase becomes
# observable.  The build-phase result is the actual signal we care about
# for this OS — it is the first place we exercise tt-metal against the
# 26.04 toolchain (gcc / glibc / Python) before upstream officially
# supports it.
FROM ubuntu:26.04

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
