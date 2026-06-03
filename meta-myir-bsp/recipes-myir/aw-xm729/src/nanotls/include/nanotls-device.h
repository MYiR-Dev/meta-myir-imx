/** @file nanotls-device.h
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

#ifndef NANOTLS_DEVICE_H
#define NANOTLS_DEVICE_H

#include <nanotls-config.h>
#include <nanotls-hooks.h>
#include <nanotls-proto.h>

enum nanotls_device_state {
	NANOTLS_DEV_UNINIT = 0,
#ifdef NANOTLS_CONFIG_HARDENING
	NANOTLS_DEV_INIT = 0x32eaf5,
	NANOTLS_DEV_HELLO_RCVD = 0x7a52ae,
	NANOTLS_DEV_HELLO_SENT = 0x5e3a0a,
	NANOTLS_DEV_DONE = 0xb09835,
	NANOTLS_DEV_ERR = 0xed2312,
#else
	NANOTLS_DEV_INIT,
	NANOTLS_DEV_HELLO_RCVD,
	NANOTLS_DEV_HELLO_SENT,
	NANOTLS_DEV_DONE,
	NANOTLS_DEV_ERR = -1,
#endif
};

struct nanotls_device_ctx {
	enum nanotls_device_state state;
	size_t error_count;

	struct nanotls_device_info device_info;

	/* ECDSA - Authentication */
	uint8_t ecdsa_priv[NANOTLS_ECDSA_PRIVATE_KEY_SIZE];

	/* ECDH - Key negotiation */
	uint8_t ecdh_priv[NANOTLS_ECDH_PRIVATE_KEY_SIZE];
	struct nanotls_key_share host_key_share;

	/* Running transcript hash context */
	nanotls_sha_ctx handshake_hash;
	uint8_t handshake_h2_hash[NANOTLS_HASH_SIZE];

	uint8_t handshake_secret[NANOTLS_SECRET_SIZE];
	uint8_t master_secret[NANOTLS_SECRET_SIZE];
};

/**
 * Initialize the device handshake context.
 *
 * @param ctx device handshake context
 * @param ecdsa_priv device ECDSA private key (matching the host public key)
 * @param device_info device information to be forwarded to the host as part of
 * DeviceHello. Could optionally be NULL, then device_info will be filled with
 * zeroes.
 * @return E_OK in case of success, error code otherwise
 */
enum ecode
nanotls_device_init(struct nanotls_device_ctx *ctx,
		    const uint8_t ecdsa_priv[NANOTLS_ECDSA_PRIVATE_KEY_SIZE],
		    const struct nanotls_device_info *device_info);

enum ecode nanotls_device_host_hello_rcvd(struct nanotls_device_ctx *ctx,
					  const struct nanotls_host_hello *msg);
enum ecode nanotls_device_do_hello(struct nanotls_device_ctx *ctx,
				   struct nanotls_device_hello *msg);

enum ecode nanotls_device_host_finished_rcvd(struct nanotls_device_ctx *ctx,
					     struct nanotls_host_finished *msg);

enum ecode nanotls_device_derive_traffic_keys_instance(
	const struct nanotls_device_ctx *ctx, struct nanotls_traffic_keys *keys,
	size_t instance_idx);

enum ecode
nanotls_device_derive_traffic_keys(const struct nanotls_device_ctx *ctx,
				   struct nanotls_traffic_keys *keys);

enum ecode nanotls_device_cleanup(struct nanotls_device_ctx *ctx);

#endif /* NANOTLS_DEVICE_H */
