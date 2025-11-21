"""Wrapper around rpmpack tar2rpm to expose richer metadata.

rpmpack's built-in pkg_tar2rpm rule does not surface summary/description/license/url,
so we invoke tar2rpm directly. This keeps packaging hermetic without rpmbuild
(see https://github.com/bazelbuild/rules_pkg/issues/29).
"""

def _rpmpack_rpm_impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.out or ctx.label.name + ".rpm")

    args = ctx.actions.args()
    args.add("--name", ctx.attr.pkg_name)
    args.add("--version", ctx.attr.version)
    args.add("--release", ctx.attr.release)
    args.add("--arch", ctx.attr.arch)
    args.add("--summary", ctx.attr.summary)
    args.add("--licence", ctx.attr.license)
    args.add("--url", ctx.attr.url)
    if ctx.attr.packager:
        args.add("--packager", ctx.attr.packager)
    if ctx.file.description_file:
        args.add("--description", ctx.file.description_file)
    if ctx.attr.epoch != None:
        args.add("--epoch", ctx.attr.epoch)
    for req in ctx.attr.requires:
        args.add("--requires", req)

    args.add("--file", out)
    args.add(ctx.file.data)

    inputs = [ctx.file.data]
    if ctx.file.description_file:
        inputs.append(ctx.file.description_file)

    ctx.actions.run(
        executable = ctx.executable.tar2rpm,
        arguments = [args],
        inputs = inputs,
        outputs = [out],
        mnemonic = "RpmpackRpm",
    )

    return DefaultInfo(files = depset([out]))

rpmpack_rpm = rule(
    implementation = _rpmpack_rpm_impl,
    attrs = {
        "arch": attr.string(
            doc = "RPM architecture (e.g., x86_64, aarch64).",
            mandatory = True,
        ),
        "data": attr.label(
            allow_single_file = [".tar"],
            doc = "Tarball input for rpmpack.",
            mandatory = True,
        ),
        "description_file": attr.label(
            allow_single_file = True,
            doc = "Description text file.",
        ),
        "epoch": attr.int(
            doc = "Optional epoch.",
        ),
        "license": attr.string(
            doc = "License string passed to rpmpack --licence.",
            mandatory = True,
        ),
        "out": attr.string(
            doc = "Output RPM filename; defaults to <name>.rpm.",
        ),
        "packager": attr.string(
            doc = "Packager field.",
            default = "",
        ),
        "pkg_name": attr.string(
            doc = "RPM package name.",
            mandatory = True,
        ),
        "release": attr.string(
            doc = "Release string.",
            mandatory = True,
        ),
        "requires": attr.string_list(
            doc = "Runtime requirements.",
            default = [],
        ),
        "summary": attr.string(
            doc = "One-line summary.",
            mandatory = True,
        ),
        "tar2rpm": attr.label(
            default = "@rpmpack//cmd/tar2rpm",
            cfg = "exec",
            executable = True,
        ),
        "url": attr.string(
            doc = "Project URL.",
            default = "",
        ),
        "version": attr.string(
            doc = "Package version.",
            mandatory = True,
        ),
    },
)
