"""Rules for Watchman binaries by target triple."""

load("@with_cfg.bzl", "with_cfg")

_dist_builder = with_cfg(native.filegroup)
_dist_builder.set("strip", "always")

_linux_x86_64_builder = _dist_builder.clone()
_linux_x86_64_builder.set("platforms", [Label("//bazel/platforms:linux_x64")])
linux_x86_64_dist, _linux_x86_64_dist_internal = _linux_x86_64_builder.build()

_linux_aarch64_builder = _dist_builder.clone()
_linux_aarch64_builder.set("platforms", [Label("//bazel/platforms:linux_arm64")])
linux_aarch64_dist, _linux_aarch64_dist_internal = _linux_aarch64_builder.build()

_macos_aarch64_builder = _dist_builder.clone()
_macos_aarch64_builder.set("platforms", [Label("@llvm//platforms:macos_arm64")])
macos_aarch64_dist, _macos_aarch64_dist_internal = _macos_aarch64_builder.build()
