# RPM build & UBI9 smoke-test notes

Quick scratchpad for reproducing the RPM build and validating install on Red Hat UBI9 (latest). Remove after use.

## Build artifacts

From repo root:

```
./build.sh
```

Outputs of interest land in `bin/`:

- `bin/bazelisk-x86_64.rpm`
- `bin/bazelisk-aarch64.rpm`

Metadata sanity check:

```
rpm -qpi bin/bazelisk-aarch64.rpm
rpm -qpl --dump bin/bazelisk-aarch64.rpm
```

Expect `Version: v1.27.0-23-gb8730b1`, `Release: 1`, `Architecture` matching the RPM, and only `/usr/bin/bazel` (symlink) + `/usr/bin/bazelisk` as payload files.

## Red Hat UBI9 (latest) install smoke test

Image matches the devcontainer base (`registry.access.redhat.com/ubi9/ubi-minimal:latest`). The example below ran on an aarch64 host; swap the RPM name if on x86_64.

```
docker run --rm -v "$PWD/bin:/tmp/bin:ro" registry.access.redhat.com/ubi9/ubi-minimal:latest \
  bash -lc 'set -euo pipefail; \
    microdnf update -y >/dev/null && \
    microdnf install -y ca-certificates >/dev/null && \
    rpm -Uvh /tmp/bin/bazelisk-aarch64.rpm && \
    bazelisk version'
```

Expected:

- rpm installs without `/usr/bin` ownership conflicts (rpmpack invoked with `--use_dir_allowlist`).
- `bazelisk version` prints the stamped Bazelisk version and downloads/runs Bazel (warns about batch mode outside a workspace; normal).

If running on x86_64, replace the RPM name accordingly. If the host lacks Docker, this container test must be rerun elsewhere.
