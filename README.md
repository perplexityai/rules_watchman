# rules_watchman

Hermetic Bazel build for Watchman `v2026.07.06.00` using
[`hermetic-llvm`](https://github.com/hermeticbuild/hermetic-llvm).

Supported targets:

- Linux x64 (`x86_64-linux-gnu`)
- Linux arm64 (`aarch64-linux-gnu`)
- Darwin arm64 (`aarch64-apple-darwin`)
- Windows x64 (`x86_64-windows-gnu`)

Linux binaries statically link libc++ and third-party dependencies; glibc remains
dynamic. Darwin uses the Apple system runtime and frameworks. Windows uses
Clang, MinGW-w64, UCRT, and libc++; it does not use the MSVC ABI. The optional
`should_deelevate_on_startup` hook is disabled in the Windows Bazel build.

Build any supported target from a registered host:

```sh
bazel build //:watchman-x86_64-linux-gnu
bazel build //:watchman-aarch64-linux-gnu
bazel build //:watchman-aarch64-apple-darwin
bazel build //:watchman-x86_64-windows-gnu
```

Build every distribution binary from one host:

```sh
bazel build //:dist
```

Run the filesystem smoke test with a binary on its matching host:

```sh
tests/watchman_smoke_test.sh /path/to/watchman
```

```powershell
tests/watchman_smoke_test.ps1 -Watchman C:\path\to\watchman.exe
```

## Development

Install the development hooks once after cloning:

```sh
npm ci
```

Commit messages and pull request titles use Conventional Commits, for example
`feat: add a target` or `fix: correct state directory resolution`.

## License

Copyright 2026 Perplexity AI.

Licensed under the [Apache License 2.0](LICENSE).
