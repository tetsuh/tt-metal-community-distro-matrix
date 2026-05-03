# Dockerfile for Debian 13 "trixie".
#
# Same policy as os/debian/12/Dockerfile: layer a minimal bootstrap on top
# of the official `debian:13` image, satisfying the preconditions of
# tt-metal's install_dependencies.sh debian path (prep_ubuntu_system) and
# papering over a small number of gaps (notably Kitware not publishing a
# Debian-codename apt repository). See os/debian/README.md for a full
# list of workarounds and rationale.
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
        software-properties-common \
        equivs \
 && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
 && locale-gen en_US.UTF-8 \
 && rm -rf /var/lib/apt/lists/*

# Workaround: provide a dummy `kitware-archive-keyring` package. Debian 13
# (trixie) ships CMake 3.31, which already exceeds the upstream Kitware
# package; we just need to keep install_dependencies.sh happy without
# fetching from apt.kitware.com/ubuntu/trixie (which 404s).
RUN printf 'Package: kitware-archive-keyring\nVersion: 9999\nMaintainer: tt-metal-community-bot <bot@example.invalid>\nArchitecture: all\nDescription: Stub providing kitware-archive-keyring on Debian.\n .\n Debian is not a supported codename for apt.kitware.com; this empty\n package satisfies install_dependencies.sh without pulling from Kitware.\n' > /tmp/kitware-archive-keyring.ctl \
 && cd /tmp \
 && equivs-build kitware-archive-keyring.ctl \
 && dpkg -i kitware-archive-keyring_9999_all.deb \
 && rm -f kitware-archive-keyring.ctl kitware-archive-keyring_9999_all.deb \
 && mkdir -p /usr/share/doc/kitware-archive-keyring \
 && printf 'Stub package; see Dockerfile.\n' > /usr/share/doc/kitware-archive-keyring/copyright

CMD ["bash"]
