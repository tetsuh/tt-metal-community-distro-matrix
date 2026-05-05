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

#
# clang-20 is pre-installed here so that tt-metal's
# `install_dependencies.sh::install_llvm` short-circuits its
# `apt.llvm.org/llvm.sh 20` invocation (which would otherwise fail
# because apt.llvm.org has not published a `resolute` pocket yet).
# Ubuntu 26.04 main/universe already provides clang-17, clang-20,
# llvm-20-dev (1:20.1.8-2ubuntu8) and cmake (4.2.3-2ubuntu2), so
# distro packages are fully sufficient.
#
# libstdc++-dev is also pre-installed: on Ubuntu 26.04 the g++ package
# no longer pulls in libstdc++-dev as a dependency, so the libstdc++.so
# symlink (needed by ld when linking with -lstdc++) would otherwise be
# absent and cmake's CXX compiler test fails immediately.
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
        clang-20 \
        g++-15 \
        libstdc++-15-dev \
 && ln -sf /usr/lib/gcc/x86_64-linux-gnu/15/libstdc++.so \
           /usr/lib/x86_64-linux-gnu/libstdc++.so \
 && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
 && locale-gen en_US.UTF-8 \
 && rm -rf /var/lib/apt/lists/*

# clang-20 on Ubuntu 26.04 does not auto-detect the gcc-15 installation
# (GCCInstallationDetector bug or packaging change).  Wrapper scripts in
# /usr/local/bin/ (which precedes /usr/bin/ in PATH) inject the required
# --gcc-install-dir flag for *every* clang invocation — including Tracy's
# ExternalProject Makefile, which overrides CFLAGS/CXXFLAGS with := and
# therefore cannot be reached via ENV CXXFLAGS.
RUN printf '#!/bin/sh\nexec /usr/bin/clang-20 --gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/15 "$@"\n' \
        > /usr/local/bin/clang-20 \
 && printf '#!/bin/sh\nexec /usr/bin/clang++-20 --gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/15 "$@"\n' \
        > /usr/local/bin/clang++-20 \
 && chmod +x /usr/local/bin/clang-20 /usr/local/bin/clang++-20

CMD ["bash"]
