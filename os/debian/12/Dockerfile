# Dockerfile for Debian 12 "bookworm".
#
# Like Rocky Linux, Debian publishes an official upstream container image,
# so we layer a minimal bootstrap on top of `debian:12` instead of
# impersonating the distro from another base. The bootstrap installs only
# what tt-metal/install_dependencies.sh assumes is already present (sudo,
# git, ca-certificates, locale data, curl, gnupg, lsb-release, wget, gpg,
# jq) so that prep_ubuntu_system can reach for its third-party apt
# repositories without further setup.
#
# Two patches still need to be applied at runtime to install_dependencies.sh
# itself; they live in the workflow's "Build tt-metal inside container" step
# rather than here so the Docker image stays free of project-specific patches.
# In short:
#   * Kitware does not publish apt repositories under the Debian codenames
#     `bookworm` or `trixie`; install_dependencies.sh's request for the
#     `<codename>` Release file returns 404 and aborts `apt-get update`.
#     Debian 12 ships CMake 3.25 and Debian 13 ships CMake 3.31, both above
#     tt-metal's `cmake_minimum_required(3.24)`, so the Kitware upgrade is
#     not strictly necessary.
#   * Debian 13 has dropped `software-properties-common` from main; the
#     workflow strips it from prep_ubuntu_system's package list. We never
#     need `add-apt-repository` because the only PPA install_dependencies.sh
#     adds (ubuntu-toolchain-r/test) is gated on `UBUNTU_CODENAME == noble`.
# See os/debian/README.md for the full rationale.
#
# We pin to ":12" (rolling 12.x). Pinning by digest is left for a follow-up
# if reproducibility becomes an issue, matching the Mint and Rocky policy.
FROM debian:12

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
