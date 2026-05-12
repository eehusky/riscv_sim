OUTPUT_ARCH( "riscv" )
ENTRY( _start )
MEMORY
{
    ITCM (rwx) : ORIGIN = 0x80000000, LENGTH = 128K
    DTCM (rw)  : ORIGIN = 0x80020000, LENGTH = 128K
}

SECTIONS
{
    .text :
    {
        _text = .;
        KEEP(*(.text.start))
        *(.text.start)
        *(.text*)
        _etext = .;
    } > ITCM

    .data : AT(ADDR(.text) + SIZEOF(.text))
    {
        _data = .;
        *(.data*)
        *(.sdata*)
        *(.rodata*)
        *(.srodata*)
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
    _heap_top = ORIGIN(DTCM) + LENGTH(DTCM) - __stack_size;

    _stack_bottom = _heap_top;
    _stack_top = ORIGIN(DTCM) + LENGTH(DTCM);
}


