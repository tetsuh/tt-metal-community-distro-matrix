# Rocky Linux entries

Unlike `os/linuxmint/`, the Rocky entries do **not** rebuild the distro from a
base Ubuntu image. Rocky Enterprise Software Foundation publishes official
container images at `quay.io/rockylinux/rockylinux`, so the Dockerfiles here
just layer the few packages that `install_dependencies.sh` and `install.sh`
take as a precondition (sudo, git, locale data, ca-certificates,
procps-ng), and enable the optional repositories tt-metal expects to be
available on a RHEL-family system:

* **EPEL** — provides `ninja-build` (and others) used by tt-metal's
  `install_dependencies.sh` / `prep_redhat_system`.
* **CRB** (CodeReady Builder) — provides `capstone-devel` and other
  development headers that tt-metal needs.

`curl` is intentionally omitted because the upstream image already ships
`curl-minimal`, and pulling in the full `curl` package conflicts with
it.

This keeps the test surface as close as possible to what a user gets from
`docker pull quay.io/rockylinux/rockylinux:N`, which is closer to the project's
mission ("see what tt-metal does on a real distro") than re-deriving the OS
ourselves.
