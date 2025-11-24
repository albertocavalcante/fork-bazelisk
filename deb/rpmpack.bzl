"""Wrapper around rpmpack tar2rpm that reads metadata files at execution time."""

def _rpmpack_rpm_impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.out or ctx.label.name + ".rpm")

    version_file = ctx.file.version_file
    description_file = ctx.file.description_file
    dir_allowlist_file = ctx.file.dir_allowlist_file

    inputs = [ctx.file.data, version_file]
    if description_file:
        inputs.append(description_file)
    if dir_allowlist_file:
        inputs.append(dir_allowlist_file)

    requires = ctx.attr.requires
    prefixes = ",".join(ctx.attr.prefixes)

    ctx.actions.run_shell(
        inputs = inputs,
        tools = [ctx.executable.tar2rpm],
        outputs = [out],
        mnemonic = "RpmpackRpm",
        progress_message = "Building RPM {} for {}".format(out.basename, ctx.attr.pkg_name),
        arguments = [
            version_file.path,
            description_file.path if description_file else "",
            ctx.file.data.path,
            out.path,
            ctx.executable.tar2rpm.path,
        ] + requires,
        env = {
            "PKG_NAME": ctx.attr.pkg_name,
            "RELEASE": ctx.attr.release,
            "ARCH": ctx.attr.arch,
            "SUMMARY": ctx.attr.summary or "",
            "LICENSE": ctx.attr.license or "",
            "URL": ctx.attr.url or "",
            "PACKAGER": ctx.attr.packager or "",
            "EPOCH": "" if ctx.attr.epoch == None else str(ctx.attr.epoch),
            "PREIN": ctx.attr.prein or "",
            "POSTIN": ctx.attr.postin or "",
            "PREUN": ctx.attr.preun or "",
            "POSTUN": ctx.attr.postun or "",
            "BUILD_TIME": ctx.attr.build_time or "",
            "PREFIXES": prefixes,
            "USE_DIR_ALLOWLIST": "1" if ctx.attr.use_dir_allowlist else "",
            "DIR_ALLOWLIST_FILE": dir_allowlist_file.path if dir_allowlist_file else "",
        },
        command = """
set -euo pipefail

version_file="$1"
description_file="$2"
tarball="$3"
out="$4"
tar2rpm="$5"
shift 5
requires=("$@")

# Normalise metadata from files to strings.
version="$(tr -d '\\n' < "$version_file")"
desc=""
if [ -n "$description_file" ]; then
  # Collapse newlines to spaces to avoid broken command lines.
  desc="$(tr '\\n' ' ' < "$description_file")"
fi

args=("$tar2rpm" "--name" "$PKG_NAME" "--version" "$version" "--release" "$RELEASE" "--arch" "$ARCH")

if [ -n "$SUMMARY" ]; then args+=(--summary "$SUMMARY"); fi
if [ -n "$LICENSE" ]; then args+=(--licence "$LICENSE"); fi
if [ -n "$URL" ]; then args+=(--url "$URL"); fi
if [ -n "$PACKAGER" ]; then args+=(--packager "$PACKAGER"); fi
if [ -n "$EPOCH" ]; then args+=(--epoch "$EPOCH"); fi
if [ -n "$PREIN" ]; then args+=(--prein "$PREIN"); fi
if [ -n "$POSTIN" ]; then args+=(--postin "$POSTIN"); fi
if [ -n "$PREUN" ]; then args+=(--preun "$PREUN"); fi
if [ -n "$POSTUN" ]; then args+=(--postun "$POSTUN"); fi
if [ -n "$BUILD_TIME" ]; then args+=(--build_time "$BUILD_TIME"); fi
if [ -n "$PREFIXES" ]; then args+=(--prefixes "$PREFIXES"); fi
if [ -n "$USE_DIR_ALLOWLIST" ]; then args+=(--use_dir_allowlist); fi
if [ -n "$DIR_ALLOWLIST_FILE" ]; then args+=(--dir_allowlist_file "$DIR_ALLOWLIST_FILE"); fi

for req in "${requires[@]}"; do
  args+=(--requires "$req")
done

if [ -n "$desc" ]; then args+=(--description "$desc"); fi

args+=(--file "$out" "$tarball")
exec "${args[@]}"
""",
    )

    return DefaultInfo(files = depset([out]))

rpmpack_rpm = rule(
    implementation = _rpmpack_rpm_impl,
    attrs = {
        "arch": attr.string(
            doc = "RPM architecture (e.g., x86_64, aarch64).",
            mandatory = True,
        ),
        "build_time": attr.string(
            doc = "Optional build_time unix timestamp.",
            default = "",
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
        "dir_allowlist_file": attr.label(
            allow_single_file = True,
            doc = "Allowlisted directories to include in the rpm.",
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
        "prein": attr.string(doc = "Pre-install scriptlet content."),
        "postin": attr.string(doc = "Post-install scriptlet content."),
        "preun": attr.string(doc = "Pre-uninstall scriptlet content."),
        "postun": attr.string(doc = "Post-uninstall scriptlet content."),
        "prefixes": attr.string_list(
            doc = "Comma-separated prefixes for relocatable packages.",
            default = [],
        ),
        "release": attr.string(
            doc = "Release string.",
            mandatory = True,
        ),
        "use_dir_allowlist": attr.bool(
            doc = "Whether to only include directories present in dir_allowlist_file.",
            default = False,
        ),
        "requires": attr.string_list(
            doc = "Runtime requirements.",
            default = [],
        ),
        "summary": attr.string(
            doc = "One-line summary.",
            default = "",
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
        "version_file": attr.label(
            allow_single_file = True,
            doc = "File containing version string.",
            mandatory = True,
        ),
    },
)
