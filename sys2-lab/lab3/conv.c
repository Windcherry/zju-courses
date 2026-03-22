#include "conv.h"

typedef unsigned long long int size_t;
uint64_t* CONV_BASE = (uint64_t*)0x10001000L;
const size_t CONV_KERNEL_OFFSET = 0;
const size_t CONV_DATA_OFFSET = 1;
const size_t CONV_RESULT_LO_OFFSET = 0;
const size_t CONV_RESULT_HI_OFFSET = 1;
const size_t CONV_STATE_OFFSET = 2;
const unsigned char READY_MASK = 0b01;
const size_t CONV_ELEMENT_LEN = 4;

uint64_t* MISC_BASE = (uint64_t*)0x10002000L;
const size_t MISC_TIME_OFFSET = 0;

uint64_t get_time(void){
    return MISC_BASE[MISC_TIME_OFFSET];
}

void conv_compute(const uint64_t* data_array, size_t data_len, const uint64_t* kernel_array, size_t kernel_len, uint64_t* dest){
    if(data_len == 0 || kernel_len == 0){
        return;
    }

    // 1. conv_kernel_init
    for(size_t i = 0; i < kernel_len; i++){
        CONV_BASE[CONV_KERNEL_OFFSET] = kernel_array[i];
    }

    // 2. pre-padding with zeros
    const size_t padding_len = kernel_len - 1;
    size_t dest_id = 0;
    const uint64_t ZERO_DATA = 0;

    for(size_t i = 0; i < padding_len; i++){
        CONV_BASE[CONV_DATA_OFFSET] = ZERO_DATA;

        while(!(CONV_BASE[CONV_STATE_OFFSET] & READY_MASK)) {};

        CONV_BASE[CONV_RESULT_HI_OFFSET];
        CONV_BASE[CONV_RESULT_LO_OFFSET];
    }

    // 3. processing data array
    for(size_t i = 0; i < data_len; i++){
        CONV_BASE[CONV_DATA_OFFSET] = data_array[i];

        while(!(CONV_BASE[CONV_STATE_OFFSET] & READY_MASK)) {};

        dest[dest_id++] = CONV_BASE[CONV_RESULT_HI_OFFSET];
        dest[dest_id++] = CONV_BASE[CONV_RESULT_LO_OFFSET];
    }

    // 4. post-padding with zeros
    for(size_t i = 0; i < padding_len; i++){
        CONV_BASE[CONV_DATA_OFFSET] = ZERO_DATA;

        while(!(CONV_BASE[CONV_STATE_OFFSET] & READY_MASK)) {};

        dest[dest_id++] = CONV_BASE[CONV_RESULT_HI_OFFSET];
        dest[dest_id++] = CONV_BASE[CONV_RESULT_LO_OFFSET];
    }
    
}

void mul_compute(const uint64_t* data_array, size_t data_len, const uint64_t* kernel_array, size_t kernel_len, uint64_t* dest){
    if (data_len == 0 || kernel_len == 0) {
        return;
    }
    
    size_t result_len = data_len + kernel_len - 1;
    
    for (size_t i = 0; i < result_len; i++) {
        dest[2 * i] = 0;
        dest[2 * i + 1] = 0;
    }
    
    uint64_t padding_len = kernel_len - 1;

    for (size_t i = 0; i < result_len; i++) {
        for (size_t j = 0; j < kernel_len; j++) {
            uint64_t data_id = i - padding_len + j;
            
            uint64_t data_value;
            if (data_id < 0 || data_id >= data_len) {
                data_value = 0;
            } else {
                data_value = data_array[data_id];
            }
            
            uint64_t kernel_value = kernel_array[j];
            
            uint64_t product_hi = 0;
            uint64_t product_lo = 0;
            
            // Multiply the data and kernel values
            for (int k = 0; k < 64; k++) {
                if (kernel_value & (1ULL << k)) {
                    uint64_t shifted_data_lo = data_value << k;
                    uint64_t shifted_data_hi = (k == 0) ? 0 : (data_value >> (64 - k)); 
                    
                    uint64_t new_lo = product_lo + shifted_data_lo;
                    uint64_t carry = (new_lo < product_lo) ? 1 : 0;
                    
                    product_lo = new_lo;
                    product_hi += (shifted_data_hi + carry); 
                }
            }
            
            // Accumulate the results
            uint64_t carry_lo = (dest[2*i+1] + product_lo < dest[2*i+1]) ? 1 : 0;
            dest[2 * i] += product_hi + carry_lo;
            dest[2 * i + 1] += product_lo;
        }
    }
}