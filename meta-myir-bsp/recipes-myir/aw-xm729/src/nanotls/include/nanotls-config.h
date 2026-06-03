/** @file nanotls-config.h
 *
 * @brief This file contains the configuration macros.
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

#ifndef NANOTLS_CONFIG_H
#define NANOTLS_CONFIG_H

/* nanoTLS compile-time configuration options */

/*
 * Harden implementation against glitching, SCA, etc.
 * Will increase the code size.
 */
//#define NANOTLS_CONFIG_HARDENING

/*
 * Enable support for key update
 */
#define NANOTLS_CONFIG_KEY_UPDATE

/*
 * Maximum number of failures during handshake before transitioning
 * into error state.
 * If not defined, then there is no limit (unsafe).
 */
#ifndef NANOTLS_CONFIG_MAX_ERR_CNT
#define NANOTLS_CONFIG_MAX_ERR_CNT 4
#endif

/*
 * Maximum number of consecutive data AES-GCM tag failures before going into
 * error state and erasing the keys. If not defined, then there is no limit
 * (unsafe).
 */
#ifndef NANOTLS_CONFIG_MAX_DATA_TAG_MISMATCH_CNT
#define NANOTLS_CONFIG_MAX_DATA_TAG_MISMATCH_CNT 256
#endif

/*
 * Enable encryption during handshake.
 * ECDSA signature and Finished messages are encrypted.
 * AES-GCM is used and authentication tag is generated and verified.
 * Introduces dependency on AES API during handshake.
 *
 * NB: TLS 1.2 does not encrypt these messages, encryption introduced in TLS 1.3
 */
#define NANOTLS_CONFIG_ENCRYPTED_HANDSHAKE

#endif /* NANOTLS_CONFIG_H */
