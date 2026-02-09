#include <stdio.h>
#include <string.h>
#include "compression.h"

int main() {
    char input[] = "Hello, World!";
    char output[100];
    int compressed_size = compress_string(input, output, 100);
    printf("Original: %s\n", input);
    printf("Compressed size: %d\n", compressed_size);
    return 0;
}
