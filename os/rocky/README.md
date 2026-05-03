# Rocky Linux entries

Unlike `os/linuxmint/`, the Rocky entries do **not** rebuild the distro from a
base Ubuntu image. Rocky Enterprise Software Foundation publishes official
container images at `quay.io/rockylinux/rockylinux`, so the Dockerfiles here
just layer the few packages that `install_dependencies.sh` and `install.sh`
take as a precondition (sudo, git, locale data, ca-certificates,
procps-ng). `curl` is intentionally omitted because the upstream image
already ships `curl-minimal`, and pulling in the full `curl` package
conflicts with it.

This keeps the test surface as close as possible to what a user gets from
`docker pull quay.io/rockylinux/rockylinux:N`, which is closer to the project's
mission ("see what tt-metal does on a real distro") than re-deriving the OS
ourselves.
