# Dockerfile for Debian 12 "bookworm".
#
# Like Rocky Linux, Debian publishes an official upstream container image,
# so we layer a minimal bootstrap on top of `debian:12` instead of
# impersonating the distro from another base. The bootstrap installs only
# what tt-metal's install_dependencies.sh assumes is already present
# (sudo, git, ca-certificates, locale data, curl, gnupg, lsb-release,
# software-properties-common, wget, gpg, jq) plus a small number of
# workarounds for gaps in the upstream debian path of install_dependencies.sh.
# See os/debian/README.md for a full list of workarounds and rationale.
#
# We pin to ":12" (rolling 12.x). Pinning by digest is left for a follow-up
# if reproducibility becomes an issue, matching the Mint and Rocky policy.
FROM debian:12

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANGUAGE=en_US:en

# Bootstrap packages.
#
# tt-metal's install_dependencies.sh debian path (prep_ubuntu_system) expects
# these tools to already exist before it starts adding apt repositories
# (LLVM, Kitware) and installing the development packages: ca-certificates,
# gpg, lsb-release, wget, software-properties-common, gnupg, jq. We add
# sudo, git, curl, locales, and equivs on top because:
#   sudo / git — required by install.sh / install_dependencies.sh and absent
#     from the base debian:12 image.
#   curl — install_dependencies.sh uses wget for fetching keys, but tt-metal
#     itself and tt-installer expect curl to exist on the system PATH.
#   locales — debian:12 ships only POSIX/C locale; CMake and Python emit
#     warnings or fail outright when LC_ALL is set to en_US.UTF-8 without
#     the corresponding locale data being generated.
#   equivs — used immediately below to satisfy `kitware-archive-keyring`.
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

# Workaround: provide a dummy `kitware-archive-keyring` package.
#
# install_dependencies.sh adds the Kitware apt repository for the running
# system codename (https://apt.kitware.com/ubuntu/<codename>/) to obtain a
# bleeding-edge CMake. Kitware only publishes packages under Ubuntu code
# names (jammy, noble, ...); requests for `bookworm` or `trixie` return 404
# and the subsequent `apt-get install -y kitware-archive-keyring` fails
# with "Unable to locate package".
#
# Debian 12 already ships CMake 3.25.1 (>= the 3.24 minimum required by
# tt-metal's top-level CMakeLists.txt), so the upgrade Kitware would
# provide is not strictly necessary. We satisfy the install line by
# pre-registering an empty stub package via equivs and creating the
# copyright marker that install_dependencies.sh tests for, which keeps the
# script's control flow intact without modifying upstream sources.
RUN printf 'Package: kitware-archive-keyring\nVersion: 9999\nMaintainer: tt-metal-community-bot <bot@example.invalid>\nArchitecture: all\nDescription: Stub providing kitware-archive-keyring on Debian.\n .\n Debian is not a supported codename for apt.kitware.com; this empty\n package satisfies install_dependencies.sh without pulling from Kitware.\n' > /tmp/kitware-archive-keyring.ctl \
 && cd /tmp \
 && equivs-build kitware-archive-keyring.ctl \
 && dpkg -i kitware-archive-keyring_9999_all.deb \
 && rm -f kitware-archive-keyring.ctl kitware-archive-keyring_9999_all.deb \
 && mkdir -p /usr/share/doc/kitware-archive-keyring \
 && printf 'Stub package; see Dockerfile.\n' > /usr/share/doc/kitware-archive-keyring/copyright

CMD ["bash"]
