load("@rules_pkg//pkg:deb.bzl", "pkg_deb")
load("@rules_pkg//pkg:mappings.bzl", "pkg_attributes", "pkg_files", "pkg_mklink")
load("@rules_pkg//pkg:tar.bzl", "pkg_tar")

config_setting(
    name = "stamp_detect",
    values = {"stamp": "1"},
)

genrule(
    name = "parse_version",
    outs = ["version.txt"],
    cmd_bash = select({
        ":stamp_detect": "sed -ne 's#^STABLE_VERSION v##p' bazel-out/stable-status.txt > $@",
        "//conditions:default": "echo 0.0.0 > $@",
    }),
    cmd_bat = "echo 0.0.0 >> $@",
    stamp = True,
)

ARCHES = [
    "amd64",
    "arm64",
]

RPM_ARCHES = {
    "amd64": "x86_64",
    "arm64": "aarch64",
}

[
    pkg_tar(
        name = "bazelisk-{}_tar".format(arch),
        srcs = ["//:bazelisk-linux-{}".format(arch)],
        out = "bazelisk-{}.tar".format(arch),
        package_dir = "/usr/bin",
        remap_paths = {"bazelisk-linux_{}".format(arch): "bazelisk"},
        stamp = -1,
        symlinks = {"bazel": "bazelisk"},
    )
    for arch in ARCHES
]

pkg_mklink(
    name = "bazel_symlink",
    link_name = "/usr/bin/bazel",
    target = "bazelisk",
)

[
    pkg_files(
        name = "bazelisk-{}_files".format(arch),
        srcs = ["//:bazelisk-linux-{}".format(arch)],
        attributes = pkg_attributes(mode = "0755"),
        prefix = "/usr/bin",
        renames = {"//:bazelisk-linux-{}".format(arch): "bazelisk"},
    )
    for arch in ARCHES
]

[
    pkg_deb(
        name = "bazelisk-{}_deb".format(arch),
        out = "bazelisk-{}.deb".format(arch),
        architecture = arch,
        conflicts = [
            "bazel",
            "bazel-bootstrap",
        ],
        data = ":bazelisk-{}_tar".format(arch),
        depends = ["ca-certificates"],
        description_file = ":description.txt",
        homepage = "https://github.com/bazelbuild/bazelisk",
        license = "Apache-2.0",
        maintainer = "The Bazel Authors <bazel-dev@googlegroups.com>",
        package = "bazelisk",
        section = "contrib/devel",
        version_file = ":version.txt",
        visibility = ["//visibility:public"],
    )
    for arch in ARCHES
]

[
    genrule(
        name = "bazelisk-{}_rpm".format(arch),
        srcs = [
            ":bazelisk-{}_tar".format(arch),
            ":description.txt",
            ":version.txt",
        ],
        # rpmpack avoids the rpmbuild dependency noted in https://github.com/bazelbuild/rules_pkg/issues/29.
        outs = ["bazelisk-{}.rpm".format(RPM_ARCHES[arch])],
        cmd = """
set -euo pipefail
VERSION="$$(cat $(location :version.txt))"
DESCRIPTION="$$(cat $(location :description.txt))"
REQS=(--requires ca-certificates)
$(location @rpmpack//cmd/tar2rpm) \
  --name bazelisk \
  --version "$$VERSION" \
  --release 1 \
  --arch {rpm_arch} \
  --summary "A user-friendly launcher for Bazel" \
  --description "$$DESCRIPTION" \
  --packager "The Bazel Authors <bazel-dev@googlegroups.com>" \
  --licence "Apache-2.0" \
  --url "https://github.com/bazelbuild/bazelisk" \
  $${{REQS[@]}} \
  --file "$@" \
  $(location :bazelisk-{arch}_tar)
""".format(
            arch = arch,
            rpm_arch = RPM_ARCHES[arch],
        ),
        # rpmpack avoids rpmbuild dependency (see https://github.com/bazelbuild/rules_pkg/issues/29)
        tags = ["rpmpack"],
        tools = ["@rpmpack//cmd/tar2rpm"],
        visibility = ["//visibility:public"],
    )
    for arch in ARCHES
]
