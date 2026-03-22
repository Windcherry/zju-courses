#include <string.h>

void *memset(void *restrict dst, int c, size_t n) {
    if(n == 0){
        return dst;
    }

    // 由于填充字节，因此转化成 unsigned char 类型
    unsigned char *p = (unsigned char *)dst;
    unsigned char byte_val = (unsigned char)c;

    size_t i;
    for(i = 0; i < n; i++){
        p[i] = byte_val;
    }

    return dst;
}

size_t strnlen(const char *restrict s, size_t maxlen) {
    size_t i;
    for(i = 0; i < maxlen; i++){
        if(s[i] == '\0'){
            return i;
        }
    }

    return maxlen;
}
