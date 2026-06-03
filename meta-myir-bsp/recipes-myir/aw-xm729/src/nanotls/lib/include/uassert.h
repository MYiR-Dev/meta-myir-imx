/** @file uassert.h
 *
 * @brief This file contains the functions for assert.
 *
 *
 * Copyright 2025-2026 NXP
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

#ifndef NANOTLS_UASSERT_H
#define NANOTLS_UASSERT_H

#include <linux/types.h>

#if defined(__linux__)
#include <linux/bug.h>
#elif defined(DEBUG)
#include <assert.h>
#endif

static inline void uassert(__attribute__((unused)) bool cond)
{
#if defined(__linux__)
	BUG_ON(!cond);
#elif defined(DEBUG)
	assert(cond);
#endif
}

#endif /* NANOTLS_UASSERT_H */
