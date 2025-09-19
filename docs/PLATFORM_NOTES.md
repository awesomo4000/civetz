# Platform-Specific Build Notes

## Supported Platforms

### ✅ Fully Supported (9 platforms)
- **Linux** x86_64, aarch64
- **macOS** x86_64, aarch64
- **Windows** x86_64, aarch64
- **FreeBSD** x86_64, aarch64
- **NetBSD** x86_64

### ⚠️ Known Issues

#### NetBSD aarch64
**Status**: Build fails with undefined `alloca` symbol

**Issue**: The CivetWeb source uses Variable Length Arrays (VLAs) in `handle_directory_request` which the compiler implements using `alloca()` for stack allocation. NetBSD aarch64 doesn't provide `alloca` in its libc.

**Attempted Fixes**:
1. `-Dalloca=malloc` - Doesn't work due to memory leak concerns
2. `-fno-stack-protector` - Doesn't resolve the missing symbol
3. Fixed stack sizes - Would require patching CivetWeb source

**Workaround**: None currently. This is a known limitation of the NetBSD aarch64 platform.

**Alternative**: Use NetBSD x86_64 which builds successfully.

## Binary Sizes

| Platform | Architecture | Size | Notes |
|----------|-------------|------|-------|
| macOS | x86_64 | 622KB | Smallest |
| macOS | aarch64 | 700KB | Native M1/M2 |
| FreeBSD | aarch64 | 709KB | |
| Windows | aarch64 | 720KB | ARM64 |
| FreeBSD | x86_64 | 726KB | |
| NetBSD | x86_64 | 738KB | |
| Windows | x86_64 | 789KB | |
| Linux | aarch64 | 803KB | ARM64 |
| Linux | x86_64 | 810KB | Largest |

## Build Script

Use `tools/compile-all-platforms.sh` to build all supported platforms automatically.

## Cross-Compilation

Zig's built-in cross-compilation works seamlessly for all supported platforms. No additional toolchains or SDKs are required.

Example:
```bash
zig build -Dtarget=x86_64-linux -Doptimize=ReleaseSmall
```