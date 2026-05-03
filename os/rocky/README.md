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

We also swap the upstream image's `curl-minimal` for the full `curl`
package, because tt-metal's `install_dependencies.sh` installs the
full `curl` unconditionally and the two packages conflict.

A handful of extra utilities are added on top of the Rocky base image
to fill gaps that `prep_redhat_system` does not cover:

* `patch` — used by CPM (CMake package manager) to apply third-party
  patches. Missing from the base image and not installed by
  `prep_redhat_system`.
* `file` — used by the SFPI compiler probe (`xargs file ...`).
* `zlib-devel` — required by tt-metal's CMake (`ZLIB::ZLIB`).

Finally, the Dockerfile sets `PATH`, `PKG_CONFIG_PATH`, and
`LD_LIBRARY_PATH` so that the OpenMPI implementation that
`prep_redhat_system` installs (under `/usr/lib64/openmpi/`) is
discoverable without `module load mpi/openmpi-x86_64`.

This keeps the test surface as close as possible to what a user gets from
`docker pull quay.io/rockylinux/rockylinux:N`, which is closer to the project's
mission ("see what tt-metal does on a real distro") than re-deriving the OS
ourselves.
