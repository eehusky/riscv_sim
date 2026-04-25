#include <stdint.h>
#include <stddef.h>

extern int __rodata_end;
extern int __data_start;
extern int __data_end;
extern int __bss_start;
extern int __bss_end;



extern int _ram_start;
extern int _text;
extern int _etext;
extern int _data;
extern int _edata;
extern int _bss;
extern int _ebss;
extern int _sbss;
extern int _esbss;
extern int _heap_bottom;
extern int _heap_top;
extern int _stack_bottom;
extern int _stack_top;

extern int _stack_size;


static void* _rsd_memcpy(void* dest_, const void* src_, size_t n) {
    uint8_t* dest = dest_;
    const uint8_t* src = src_;

    for (size_t i = 0; i < n; i++) {
        dest[i] = src[i];
    }
    return dest;
}

static void* _rsd_memset(void* str_, int c, size_t n) {
    uint8_t* str = str_;
    for (size_t i = 0; i < n; i++) {
        str[i] = (uint8_t)c;
    }
    return str;
}

void _load() {
    // The core function of the RSD loader called at the very beggining of run time.
    // It copies data in .data and .sdata sections from ROM to RAM
    // and sets 0 in .bss and .sbss sections in RAM.
    //size_t data_size = (size_t)&_edata - (size_t)&_data;
    size_t bss_size = (size_t)&_esbss - (size_t)&_bss;
    ////_rsd_memcpy((void*)_ram_start, &__rodata_end, data_size);
    _rsd_memset(&_bss, 0, bss_size);
}
