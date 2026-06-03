/** @file nanotls-host.h
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

#ifndef NANOTLS_HOST_H
#define NANOTLS_HOST_H

#include <nanotls-config.h>
#include <nanotls-hooks.h>
#include <nanotls-proto.h>

enum nanotls_host_state {
	NANOTLS_HOST_UNINIT = 0,
#ifdef NANOTLS_CONFIG_HARDENING
	NANOTLS_HOST_INIT = 0x32eaf5,
	NANOTLS_HOST_HELLO_SENT = 0x7a52ae,
	NANOTLS_HOST_HELLO_RCVD = 0x5e3a0a,
	NANOTLS_HOST_DONE = 0xb09835,
	NANOTLS_HOST_ERR = 0xed2312,
#else
	NANOTLS_HOST_INIT,
	NANOTLS_HOST_HELLO_SENT,
	NANOTLS_HOST_HELLO_RCVD,
	NANOTLS_HOST_DONE,
	NANOTLS_HOST_ERR = -1,
#endif
};

struct nanotls_host_ctx;

/**
 * Public key request callback.
 * A callback called from nanotls_host_device_hello_rcvd() called to
 * request a device public key if it has not been provided during context init
 * time.
 * @param ctx [in] host handshake context (for reference)
 * @param device_info [in] device information data provided by the device in
 * DeviceHello. Could be used by the driver to narrow down the FW image search.
 * @param ecdsa_pub [out] destination buffer callback function should write
 *        resulting ecdsa public key to
 * @return E_OK in case of public key found and successfully written to
 * ecdsa_pub buffer, error code otherwise
 */
typedef enum ecode (*nanotls_host_pub_key_req_cb)(
	const struct nanotls_host_ctx *ctx,
	const struct nanotls_device_info *device_info,
	uint8_t ecdsa_pub[NANOTLS_ECDSA_PUBLIC_KEY_SIZE]);

struct nanotls_host_ctx {
	enum nanotls_host_state state;
	size_t error_count;

	struct nanotls_device_info device_info;

	/* ECDSA - Authentication */
	uint8_t ecdsa_pub[NANOTLS_ECDSA_PUBLIC_KEY_SIZE];
	nanotls_host_pub_key_req_cb pub_key_req_cb; /* callback to request the
						       public key */

	/* ECDH - Key negotiation */
	uint8_t ecdh_priv[NANOTLS_ECDH_PRIVATE_KEY_SIZE];
	struct nanotls_key_share device_key_share;

	/* Running transcript hash context */
	nanotls_sha_ctx handshake_hash;
	uint8_t handshake_h2_hash[NANOTLS_HASH_SIZE];

	uint8_t handshake_secret[NANOTLS_SECRET_SIZE];
	uint8_t master_secret[NANOTLS_SECRET_SIZE];
};

/**
 * Initialize the host handshake context with the known public key.
 *
 * This init function flavor assumes the public key is known at the init time.
 *
 * @param ctx host handshake context
 * @param ecdsa_pub host ECDSA public key (matching the device private key)
 * @return E_OK in case of success, error code otherwise
 */
enum ecode
nanotls_host_init(struct nanotls_host_ctx *ctx,
		  const uint8_t ecdsa_pub[NANOTLS_ECDSA_PUBLIC_KEY_SIZE]);

/**
 * Initialize the host handshake context with deferred public key lookup.
 *
 * This init function flavor assumes the public key is not known at the init
 * time, so the pub_key_req_cb callback is called from
 * nanotls_host_device_hello_rcvd() to look up and provide the public key using
 * device_info provided in DeviceHello.
 *
 * @param ctx host handshake context
 * @param pub_key_req_cb a callback to be called from
 * nanotls_host_device_hello_rcvd() to provide lookup for the public key using
 * device_info provided in DeviceHello.
 * @return E_OK in case of success, error code otherwise
 */
enum ecode
nanotls_host_init_pubkey_cb(struct nanotls_host_ctx *ctx,
			    nanotls_host_pub_key_req_cb pub_key_req_cb);

enum ecode nanotls_host_do_hello(struct nanotls_host_ctx *ctx,
				 struct nanotls_host_hello *msg);

enum ecode nanotls_host_device_hello_rcvd(struct nanotls_host_ctx *ctx,
					  struct nanotls_device_hello *msg);

/* Get device info after DeviceHello has been processed */
enum ecode
nanotls_host_get_device_info(const struct nanotls_host_ctx *ctx,
			     struct nanotls_device_info *device_info);

enum ecode nanotls_host_do_finished(struct nanotls_host_ctx *ctx,
				    struct nanotls_host_finished *msg);

enum ecode
nanotls_host_derive_traffic_keys_instance(const struct nanotls_host_ctx *ctx,
					  struct nanotls_traffic_keys *keys,
					  size_t instance_idx);

enum ecode nanotls_host_derive_traffic_keys(const struct nanotls_host_ctx *ctx,
					    struct nanotls_traffic_keys *keys);

enum ecode nanotls_host_cleanup(struct nanotls_host_ctx *ctx);

#endif /* NANOTLS_HOST_H */
