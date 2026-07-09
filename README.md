# rules_watchman

Hermetic Bazel build for Watchman `v2026.07.06.00` using
[`hermetic-llvm`](https://github.com/hermeticbuild/hermetic-llvm).

Supported targets:

- Linux x64
- Linux arm64
- Darwin arm64

Linux binaries statically link libc++ and third-party dependencies; glibc remains
dynamic. Darwin uses the Apple system runtime and frameworks.

Build a binary:

```sh
bazel build --config=linux-x64 //:watchman
bazel build --config=linux-arm64 //:watchman
bazel build --config=darwin-arm64 //:watchman
```

Run the filesystem smoke test on the matching host:

```sh
bazel test --config=darwin-arm64 --build_tests_only //...
```

Build an optimized distribution binary:

```sh
bazel build --config=linux-x64 --config=dist //:dist
```
