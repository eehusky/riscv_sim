_stack_size = 4K;

MEMORY
{
    ITCM (rwx) : ORIGIN = 0x80000000, LENGTH = 64K
    DTCM (rwx) : ORIGIN = 0x80010000, LENGTH = 64K
}

SECTIONS
{
    .text :
    {
        _text = .;
        KEEP(*(.text.start))
        *(.text.start)
        *(.text*)
        *(.rodata*)
        *(.srodata*)
        _etext = .;
    } > ITCM

    .data : AT(ADDR(.text) + SIZEOF(.text))
    {
        _data = .;
        *(.data*)
        *(.sdata*)
        _edata = .;
    } > DTCM

    .bss : AT(ADDR(.data) + SIZEOF(.data))
    {
        _bss = .;
        *(.bss*)
        *(COMMON)
        _ebss = .;
    } > DTCM

    .sbss : AT(ADDR(.bss) + SIZEOF(.bss))
    {
        _sbss = .;
        *(.sbss*)
        _esbss = .;
    } > DTCM

    _heap_bottom = .;
    _heap_top = ORIGIN(DTCM) + LENGTH(DTCM) - _stack_size;

    _stack_bottom = _heap_top;
    _stack_top = ORIGIN(DTCM) + LENGTH(DTCM);

}


