/** @file nanotls-hooks.h
 *
 * @brief This file contains the declarations, type definitions.
 *
 *
 * Copyright 2025 NXP
 *
 * This software file (the File) is distributed by NXP
 * under the terms of the GNU General Public License Version 2, June 1991
 * (the License).  You may use, redistribute and/or modify the File in
 * accordance with the terms and conditions of the License, a copy of which
 * is available by writing to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA or on the
 * worldwide web at http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.
 *
 * THE FILE IS DISTRIBUTED AS-IS, WITHOUT WARRANTY OF ANY KIND, AND THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE
 * ARE EXPRESSLY DISCLAIMED.  The License provides additional details about
 * this warranty disclaimer.
 *
 */

#ifndef NANOTLS_HOOKS_H
#define NANOTLS_HOOKS_H

#include <linux/types.h>
#include <asm/string.h>
#include <nanotls-types.h>
#include <sha2.h>
#include <hmac.h>
#include <gcm.h>

#define NANOTLS_SHA256_HASH_SIZE 32
#define NANOTLS_SHA256_BLOCK_SIZE 64

typedef cf_sha256_context nanotls_sha_ctx;
typedef cf_hmac_ctx nanotls_hmac_ctx;

#if 0
#define MIN(a, b) ((a) <= (b) ? (a) : (b))
#define MAX(a, b) ((a) >= (b) ? (a) : (b))
#endif
#define ROUND_UP(x, align) ((((x) + (align)-1) / (align)) * (align))
#define ROUND_DN(x, align) (((x) / (align)) * (align))

// TODO: cleanup
//#define DIV_ROUND_UP(x, y)      (((x) + (y)-1) / (y))

enum ecode nanotls_secure_random(void *buf, size_t size);

enum ecode nanotls_p256_gen_keypair(uint8_t priv[32], uint8_t pub[64]);
enum ecode nanotls_p256_ecdh_shared_secret(uint8_t secret[32],
					   const uint8_t priv[32],
					   const uint8_t pub[64]);
enum ecode nanotls_p256_ecdsa_sign(uint8_t sig[64], const uint8_t priv[32],
				   const uint8_t *hash, size_t hlen);
enum ecode nanotls_p256_ecdsa_verify(const uint8_t sig[64],
				     const uint8_t pub[64], const uint8_t *hash,
				     size_t hlen);

enum ecode nanotls_sha256_init(nanotls_sha_ctx *ctx);
enum ecode nanotls_sha256_update(nanotls_sha_ctx *ctx, const void *buf,
				 size_t size);
enum ecode nanotls_sha256_digest(const nanotls_sha_ctx *ctx,
				 uint8_t hash[NANOTLS_SHA256_HASH_SIZE]);
enum ecode nanotls_sha256_digest_final(nanotls_sha_ctx *ctx,
				       uint8_t hash[NANOTLS_SHA256_HASH_SIZE]);

enum ecode nanotls_hmac_sha256_init(nanotls_hmac_ctx *ctx, const void *key,
				    size_t key_size);
enum ecode nanotls_hmac_sha256_update(nanotls_hmac_ctx *ctx, const void *data,
				      size_t data_size);
enum ecode nanotls_hmac_sha256_finish(nanotls_hmac_ctx *ctx,
				      uint8_t result[NANOTLS_SHA256_HASH_SIZE]);
enum ecode nanotls_hmac_sha256(const void *key, size_t key_size,
			       const void *data, size_t data_size,
			       uint8_t result[NANOTLS_SHA256_HASH_SIZE]);

/*
 * AES API - needed post-handshake.
 * Only AES-GCM-128 is supported with fixed 12 byte IV size.
 */

#define NANOTLS_AES_KEY_SIZE 16
#define NANOTLS_AES_IV_SIZE 12
#define NANOTLS_AES_GCM_TAG_SIZE 16

typedef gcm_context nanotls_aes_context;

enum ecode nanotls_aes_ctx_init(nanotls_aes_context *ctx,
				const uint8_t key[NANOTLS_AES_KEY_SIZE]);
enum ecode nanotls_aes_start_enc(nanotls_aes_context *ctx,
				 const uint8_t iv[NANOTLS_AES_IV_SIZE],
				 const void *add, size_t add_size);
enum ecode nanotls_aes_start_dec(nanotls_aes_context *ctx,
				 const uint8_t iv[NANOTLS_AES_IV_SIZE],
				 const void *add, size_t add_size);
/*
 * All but the final invocation MUST be called with length mod 16 == 0.
 * Only the final call can have a partial block length of < 128 bits.
 */
enum ecode nanotls_aes_update(nanotls_aes_context *ctx, void *out,
			      const void *in, size_t data_size);
enum ecode nanotls_aes_finish(nanotls_aes_context *ctx,
			      uint8_t tag[NANOTLS_AES_GCM_TAG_SIZE]);
enum ecode nanotls_aes_ctx_destroy(nanotls_aes_context *ctx);

enum ecode nanotls_aes_encrypt(nanotls_aes_context *ctx, void *out_data,
			       const void *in_data, size_t data_size,
			       const uint8_t iv[NANOTLS_AES_IV_SIZE],
			       const void *add, size_t add_size,
			       uint8_t tag[NANOTLS_AES_GCM_TAG_SIZE]);

enum ecode nanotls_aes_decrypt(nanotls_aes_context *ctx, void *out_data,
			       const void *in_data, size_t data_size,
			       const uint8_t iv[NANOTLS_AES_IV_SIZE],
			       const void *add, size_t add_size,
			       uint8_t tag[NANOTLS_AES_GCM_TAG_SIZE]);

#endif /* NANOTLS_HOOKS_H */
