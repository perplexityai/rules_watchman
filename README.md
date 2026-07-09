# rules_watchman

Hermetic Bazel build for Watchman `v2026.07.06.00` using
[`hermetic-llvm`](https://github.com/hermeticbuild/hermetic-llvm).

Supported targets:

- Linux x64 (`x86_64-linux-gnu`)
- Linux arm64 (`aarch64-linux-gnu`)
- Darwin arm64 (`aarch64-apple-darwin`)

Linux binaries statically link libc++ and third-party dependencies; glibc remains
dynamic. Darwin uses the Apple system runtime and frameworks.

Build any supported target from a registered host:

```sh
bazel build //:watchman-x86_64-linux-gnu
bazel build //:watchman-aarch64-linux-gnu
bazel build //:watchman-aarch64-apple-darwin
```

Build every distribution binary from one host:

```sh
bazel build //:dist
```

Run the filesystem smoke test with a binary on its matching host:

```sh
tests/watchman_smoke_test.sh /path/to/watchman
```
