#include <stddef.h>
#include <stdlib.h>

void arc4random_buf(void *buf, size_t nbytes) {
    unsigned char *p = (unsigned char *)buf;
    while (nbytes--) {
        *p++ = (unsigned char)(rand() & 0xFF);
    }
}

unsigned int arc4random(void) {
    return (unsigned int)rand();
}

void arc4random_stir(void) {}
void arc4random_addrandom(unsigned char *dat, int datlen) {}
