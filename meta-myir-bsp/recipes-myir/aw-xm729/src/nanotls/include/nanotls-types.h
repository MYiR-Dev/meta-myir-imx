/** @file nanotls-types.h
 *
 * @brief This file contains the type definitions.
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

#ifndef NANOTLS_TYPES_H
#define NANOTLS_TYPES_H

#include <nanotls-config.h>

enum nanotls_role {
	NANOTLS_ROLE_UNKNOWN = 0,
#ifdef NANOTLS_CONFIG_HARDENING
	NANOTLS_ROLE_HOST = 0x1ea71e,
	NANOTLS_ROLE_DEVICE = 0xdb25cc,
#else
	NANOTLS_ROLE_HOST = 1,
	NANOTLS_ROLE_DEVICE = 2,
#endif
};

enum ecode {
#ifdef NANOTLS_CONFIG_HARDENING
	/* Error codes with big Hamming distance for better hardening */
	/* Not trivial enough, but still could be generated with single RISC-V
	   instruction */
	E_OK = -1446, /* 0xFFFFFA5A */
	E_INVALID = 0x153E95A5, /* Invalid value or state */
#else
	E_OK = 0,
	E_INVALID = -1,
#endif
};

#endif /* NANOTLS_TYPES_H */
