# Dockerfile for Linux Mint 22.3 "Zena" based on Ubuntu 24.04
ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION}

# set the version codename for Linux Mint and Ubuntu
ARG MINT_VERSION_CODENAME=zena
ARG UBUNTU_VERSION_CODENAME=noble

# Configure apt to run in non-interactive mode
ENV DEBIAN_FRONTEND=noninteractive
# Add basic tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl gnupg locales && \
    # Set locale
    localedef --no-archive -i en_US -f UTF-8 en_US.UTF-8 && \
    rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Add the Linux Mint GPG key
RUN curl -fsSL -o /tmp/linuxmint-keyring.deb http://packages.linuxmint.com/pool/main/l/linuxmint-keyring/linuxmint-keyring_2022.06.21_all.deb && \
    dpkg -i /tmp/linuxmint-keyring.deb && \
    rm -f /tmp/linuxmint-keyring.deb

# Create the apt repository for Linux Mint
RUN echo "deb http://packages.linuxmint.com ${MINT_VERSION_CODENAME} main upstream import backport" > /etc/apt/sources.list.d/official-package-repositories.list && \
    echo "deb http://archive.ubuntu.com/ubuntu ${UBUNTU_VERSION_CODENAME} main restricted universe multiverse" >> /etc/apt/sources.list.d/official-package-repositories.list && \
    echo "deb http://archive.ubuntu.com/ubuntu ${UBUNTU_VERSION_CODENAME}-updates main restricted universe multiverse" >> /etc/apt/sources.list.d/official-package-repositories.list && \
    echo "deb http://archive.ubuntu.com/ubuntu ${UBUNTU_VERSION_CODENAME}-backports main restricted universe multiverse" >> /etc/apt/sources.list.d/official-package-repositories.list && \
    echo "deb http://security.ubuntu.com/ubuntu ${UBUNTU_VERSION_CODENAME}-security main restricted universe multiverse" >> /etc/apt/sources.list.d/official-package-repositories.list && \
    # Mint doesn't use sources.list
    echo "#/etc/apt/sources.list" > /etc/apt/sources.list && \
    # Mint doesn't have ubuntu.sources
    rm -f /etc/apt/sources.list.d/ubuntu.sources && \
    apt-get update

# Install all required packages and clean up in a single layer to optimize image size
RUN apt-get install -y --no-install-recommends --allow-downgrades \
        # Override base-files to match Linux Mint for repository compatibility
        base-files/${MINT_VERSION_CODENAME} \
        mintsystem \
        # Install Linux Mint core packages and Cinnamon desktop environment
        mint-meta-core \
        mint-meta-cinnamon \
        # Install additional packages for tt-metal
        git && \
    # Clear apt cache and remove unnecessary packages
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Default command to run when the image starts (e.g., start a bash shell)
CMD ["bash"]
