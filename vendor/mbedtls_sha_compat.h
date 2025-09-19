#ifndef MBEDTLS_SHA_COMPAT_H
#define MBEDTLS_SHA_COMPAT_H

#include <mbedtls/sha1.h>

// OpenSSL compatibility layer for mbedTLS SHA1
typedef mbedtls_sha1_context SHA_CTX;

static inline void SHA1_Init(SHA_CTX *ctx) {
    mbedtls_sha1_init(ctx);
    mbedtls_sha1_starts(ctx);
}

static inline void SHA1_Update(SHA_CTX *ctx, const unsigned char *data, size_t len) {
    mbedtls_sha1_update(ctx, data, len);
}

static inline void SHA1_Final(unsigned char *md, SHA_CTX *ctx) {
    mbedtls_sha1_finish(ctx, md);
    mbedtls_sha1_free(ctx);
}

#endif // MBEDTLS_SHA_COMPAT_H