const std = @import("std");

pub fn build(b: *std.Build) void {
    _ = b;
}

pub fn buildCivetWeb(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, mbedtls: *std.Build.Step.Compile) !*std.Build.Step.Compile {
    const lib = b.addLibrary(.{
        .name = "civetweb",
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    lib.addIncludePath(b.path("vendor/civetweb/include"));
    lib.addIncludePath(b.path("vendor/mbedtls/include"));
    lib.addIncludePath(b.path("vendor"));  // For mbedtls_sha_compat.h

    // Build flags - add platform specific workarounds
    var flags = std.ArrayList([]const u8){};
    defer flags.deinit(b.allocator);
    try flags.appendSlice(b.allocator, &[_][]const u8{
        "-DUSE_WEBSOCKET",
        "-DUSE_MBEDTLS",
        "-DNO_SSL_DL",
        "-DBUILD_DATE=\"civetz\"",  // Avoid __DATE__ for reproducible builds
        "-std=c99",
        // TODO: Add "-DUSE_ZLIB" after vendoring zlib for static linking
    });

    // NetBSD aarch64 workaround - disable optimizations that might use alloca
    if (target.result.os.tag == .netbsd and target.result.cpu.arch == .aarch64) {
        // Skip for now - NetBSD aarch64 has issues with alloca in VLAs
        // This is a known limitation
    }

    lib.addCSourceFile(.{
        .file = b.path("vendor/civetweb/src/civetweb.c"),
        .flags = flags.items,
    });

    lib.linkLibrary(mbedtls);

    const target_info = target.result;
    if (target_info.os.tag == .windows) {
        lib.linkSystemLibrary("ws2_32");
        lib.linkSystemLibrary("advapi32");
        lib.linkSystemLibrary("bcrypt");  // For mbedTLS entropy
    } else {
        lib.linkSystemLibrary("pthread");
    }

    return lib;
}

pub fn buildMbedTLS(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const lib = b.addLibrary(.{
        .name = "mbedtls",
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    lib.addIncludePath(b.path("vendor/mbedtls/include"));

    const srcs = [_][]const u8{
        "library/aes.c",
        "library/aesce.c",
        "library/aesni.c",
        "library/aria.c",
        "library/asn1parse.c",
        "library/asn1write.c",
        "library/base64.c",
        "library/bignum.c",
        "library/bignum_core.c",
        "library/bignum_mod.c",
        "library/bignum_mod_raw.c",
        "library/camellia.c",
        "library/ccm.c",
        "library/chacha20.c",
        "library/chachapoly.c",
        "library/cipher.c",
        "library/cipher_wrap.c",
        "library/constant_time.c",
        "library/cmac.c",
        "library/ctr_drbg.c",
        "library/debug.c",
        "library/des.c",
        "library/dhm.c",
        "library/ecdh.c",
        "library/ecdsa.c",
        "library/ecjpake.c",
        "library/ecp.c",
        "library/ecp_curves.c",
        "library/ecp_curves_new.c",
        "library/entropy.c",
        "library/entropy_poll.c",
        "library/error.c",
        "library/gcm.c",
        "library/hkdf.c",
        "library/hmac_drbg.c",
        "library/nist_kw.c",
        "library/md.c",
        "library/md5.c",
        "library/net_sockets.c",
        "library/oid.c",
        "library/pem.c",
        "library/pk.c",
        "library/pk_ecc.c",
        "library/pk_wrap.c",
        "library/pkcs12.c",
        "library/pkcs5.c",
        "library/pkparse.c",
        "library/pkwrite.c",
        "library/platform.c",
        "library/platform_util.c",
        "library/poly1305.c",
        "library/psa_crypto.c",
        "library/psa_crypto_aead.c",
        "library/psa_crypto_cipher.c",
        "library/psa_crypto_client.c",
        "library/psa_crypto_driver_wrappers_no_static.c",
        "library/psa_crypto_ecp.c",
        "library/psa_crypto_ffdh.c",
        "library/psa_crypto_hash.c",
        "library/psa_crypto_mac.c",
        "library/psa_crypto_pake.c",
        "library/psa_crypto_rsa.c",
        "library/psa_crypto_se.c",
        "library/psa_crypto_slot_management.c",
        "library/psa_crypto_storage.c",
        "library/psa_its_file.c",
        "library/psa_util.c",
        "library/ripemd160.c",
        "library/rsa.c",
        "library/rsa_alt_helpers.c",
        "library/sha1.c",
        "library/sha256.c",
        "library/sha512.c",
        "library/sha3.c",
        "library/ssl_cache.c",
        "library/ssl_ciphersuites.c",
        "library/ssl_client.c",
        "library/ssl_cookie.c",
        "library/ssl_debug_helpers_generated.c",
        "library/ssl_msg.c",
        "library/ssl_ticket.c",
        "library/ssl_tls.c",
        "library/ssl_tls12_client.c",
        "library/ssl_tls12_server.c",
        "library/ssl_tls13_client.c",
        "library/ssl_tls13_generic.c",
        "library/ssl_tls13_keys.c",
        "library/ssl_tls13_server.c",
        "library/threading.c",
        "library/timing.c",
        "library/version.c",
        "library/version_features.c",
        "library/x509.c",
        "library/x509_create.c",
        "library/x509_crl.c",
        "library/x509_crt.c",
        "library/x509_csr.c",
        "library/x509write.c",
        "library/x509write_crt.c",
        "library/x509write_csr.c",
    };

    // Determine compile flags based on target OS
    const cflags = switch (target.result.os.tag) {
        .freebsd => &[_][]const u8{
            "-std=c99",
            "-D__BSD_VISIBLE",
            "-fno-sanitize=alignment",
        },
        .openbsd, .netbsd, .dragonfly => &[_][]const u8{
            "-std=c99",
            "-D_BSD_SOURCE",
            "-D_DEFAULT_SOURCE",
            "-fno-sanitize=alignment",
        },
        else => &[_][]const u8{
            "-std=c99",
            "-D_POSIX_C_SOURCE=200112L",
            "-fno-sanitize=alignment",
        },
    };

    for (srcs) |src| {
        lib.addCSourceFile(.{
            .file = b.path(b.fmt("vendor/mbedtls/{s}", .{src})),
            .flags = cflags,
        });
    }

    return lib;
}