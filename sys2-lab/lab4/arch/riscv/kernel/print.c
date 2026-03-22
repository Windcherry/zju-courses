#include <print.h>
#include <sbi.h>

void puts(const char *s) {
    int i;
    for(i = 0; s[i] != '\0'; i++){
        sbi_ecall(0x4442434e, 2, (uint64_t)s[i], 0, 0, 0, 0, 0);
    }
}

void puti(int i) {
    char output[20];    // INT 的范围是[-2147483648, 2147483647], 最长为20位
    char temp[20];

    int j = 0;
    int k = 0;
    int neg_flag = 0;

    uint64_t u;

    if(i == 0){
        output[0] = '0';
        output[1] = '\0';
        puts(output);
        return;
    }

    if(i < 0){
        neg_flag = 1;
        u = (uint64_t)-i;
    }
    else{
        u = (uint64_t)i;
    }

    while(u > 0){
        temp[k++] = u % 10 + '0';
        u /= 10;
    }

    if(neg_flag){
        output[j++] = '-';
    }

    while(k > 0){
        output[j++] = temp[--k];
    }

    output[j] = '\0';
    puts(output);
}
