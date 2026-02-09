#include <zlib.h>
#include "compression.h"

int compress_string(const char* input, char* output, int output_size) 
{
    return compress((Bytef)output, (uLongf)&output_size, (Bytef*)input, strlen(input));
}
