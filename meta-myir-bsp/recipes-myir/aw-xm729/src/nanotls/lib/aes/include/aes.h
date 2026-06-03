/******************************************************************************
 *
 * THIS SOURCE CODE IS HEREBY PLACED INTO THE PUBLIC DOMAIN FOR THE GOOD OF ALL
 *
 * This is a simple and straightforward implementation of the AES Rijndael
 * 128-bit block cipher designed by Vincent Rijmen and Joan Daemen. The focus
 * of this work was correctness & accuracy.  It is written in 'C' without any
 * particular focus upon optimization or speed. It should be endian (memory
 * byte order) neutral since the few places that care are handled explicitly.
 *
 * This implementation of Rijndael was created by Steven M. Gibson of GRC.com.
 *
 * It is intended for general purpose use, but was written in support of GRC's
 * reference implementation of the SQRL (Secure Quick Reliable Login) client.
 *
 * See:    http://csrc.nist.gov/archive/aes/rijndael/wsdindex.html
 *
 * NO COPYRIGHT IS CLAIMED IN THIS WORK, HOWEVER, NEITHER IS ANY WARRANTY MADE
 * REGARDING ITS FITNESS FOR ANY PARTICULAR PURPOSE. USE IT AT YOUR OWN RISK.
 *
 *******************************************************************************/

#ifndef AES_HEADER
#define AES_HEADER

#include <linux/types.h>
#include <asm/string.h>

#define AES_CONFIG_128_BIT_ONLY

enum aes_op_mode {
	AES_MODE_NONE = 0,
	AES_MODE_ENCRYPT = 0x231d14,
	AES_MODE_DECRYPT = 0x1676a1,
};

/******************************************************************************
 *  AES_CONTEXT : cipher context / holds inter-call data
 ******************************************************************************/
typedef struct {
	int rounds; // keysize-based rounds count
	uint32_t *rk; // pointer to current round key
	uint32_t buf[68]; // key expansion buffer
} aes_context;

/******************************************************************************
 *  AES_SETKEY : called to expand the key for encryption or decryption
 ******************************************************************************/
int aes_setkey(aes_context *ctx, // pointer to context
	       const uint8_t *key, // AES input key
	       size_t keysize); // size in bytes (must be 16, 24, 32 for
				// 128, 192 or 256-bit keys respectively)
				// returns 0 for success

/******************************************************************************
 *  AES_CIPHER : called to encrypt or decrypt ONE 128-bit block of data
 ******************************************************************************/
int aes_cipher(aes_context *ctx, // pointer to context
	       const uint8_t input[16], // 128-bit block to en/decipher
	       uint8_t output[16]); // 128-bit output result block
				    // returns 0 for success
				    //
/******************************************************************************
 *  AES_SET_ENCRYPTION_KEY : called to set encryption key
 ******************************************************************************/
int aes_set_encryption_key(aes_context *ctx, const uint8_t *key,
			   size_t keysize);

#endif /* AES_HEADER */
