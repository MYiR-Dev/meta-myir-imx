/** @file nanotls-common.c
 *
 * @brief This file contains the common functions for nanotls.
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

#include <nanotls-common.h>
#include <asm/string.h>

#include "uassert.h"

enum ecode nanotls_mem_eq(const void *a, const void *b, size_t size)
{
	const volatile uint8_t *va = a;
	const volatile uint8_t *vb = b;
	uint8_t diff = 0;

	while (size--) {
		diff |= *va++ ^ *vb++;
	}

	return (diff == 0) ? E_OK : E_INVALID;
}

void nanotls_mem_erase(void *buf, size_t size)
{
	memset(buf, 0, size);
}

void nanotls_hkdf_sha256_extract(const void *salt, size_t salt_len,
				 const void *ikm, size_t ikm_len,
				 uint8_t prk_result[NANOTLS_SHA256_HASH_SIZE])
{
	if (salt_len > 0) {
		nanotls_hmac_sha256(salt, salt_len, ikm, ikm_len, prk_result);
	} else {
		uint8_t zeroes[NANOTLS_SHA256_HASH_SIZE] = {0};

		nanotls_hmac_sha256(zeroes, NANOTLS_SHA256_HASH_SIZE, ikm,
				    ikm_len, prk_result);
	}
}

void nanotls_hkdf_expand_label(const uint8_t secret[NANOTLS_SHA256_HASH_SIZE],
			       const void *label, size_t label_size,
			       const uint8_t *context, size_t context_size,
			       void *output, size_t output_length)
{
	uint8_t hmac_out[NANOTLS_SHA256_HASH_SIZE];
	nanotls_hmac_ctx hmac_ctx;
	const uint16_t length = output_length;
	const uint8_t one = 0x01;

	uassert(length <= NANOTLS_SHA256_HASH_SIZE);

	nanotls_hmac_sha256_init(&hmac_ctx, secret, NANOTLS_SHA256_HASH_SIZE);

	nanotls_hmac_sha256_update(&hmac_ctx, &length, sizeof(length));
	nanotls_hmac_sha256_update(&hmac_ctx, label, label_size);

	if (context && context_size > 0)
		nanotls_hmac_sha256_update(&hmac_ctx, context, context_size);

	nanotls_hmac_sha256_update(&hmac_ctx, &one, sizeof(one));

	nanotls_hmac_sha256_finish(&hmac_ctx, hmac_out);

	memcpy(output, hmac_out, output_length);

	nanotls_mem_erase(hmac_out, sizeof(hmac_out));
}

void nanotls_write_finished(const nanotls_sha_ctx *handshake_hash,
			    const uint8_t hs_traffic_secret[NANOTLS_SECRET_SIZE],
			    uint8_t verify_data[NANOTLS_SHA256_HASH_SIZE])
{
	uint8_t transcript_hash[NANOTLS_SHA256_HASH_SIZE];
	uint8_t finished_key[NANOTLS_SHA256_HASH_SIZE]; /* HMAC key (not AES),
							   hence it's bigger */

	/* Calculate transcript hash (transcript_hash) */
	nanotls_sha256_digest(handshake_hash, transcript_hash);

	/*
	 * Derive "Finished" key
	 * finished_key = HKDF-Expand-Label(hs_traffic_secret, "finished", "",
	 * Hash.length)
	 */
	nanotls_hkdf_expand_label_noctx(hs_traffic_secret,
					NANOTLS_FINISHED_LABEL, finished_key,
					sizeof(finished_key));

	/*
	 * Create Finished.verify_data
	 * verify_data = HMAC(finished_key, transcript_hash)
	 */
	nanotls_hmac_sha256(finished_key, sizeof(finished_key), transcript_hash,
			    sizeof(transcript_hash), verify_data);

	nanotls_mem_erase(finished_key, sizeof(finished_key));
}

void nanotls_derive_key_iv(uint8_t key[NANOTLS_KEY_SIZE],
			   uint8_t iv[NANOTLS_IV_SIZE],
			   const uint8_t secret[NANOTLS_SECRET_SIZE])
{
	/* key = HKDF-Expand-Label(secret, "key", "") */
	nanotls_hkdf_expand_label_noctx(secret, NANOTLS_KEYING_KEY_LABEL, key,
					NANOTLS_KEY_SIZE);

	/* iv = HKDF-Expand-Label(secret, "iv", "") */
	nanotls_hkdf_expand_label_noctx(secret, NANOTLS_KEYING_IV_LABEL, iv,
					NANOTLS_IV_SIZE);
}
