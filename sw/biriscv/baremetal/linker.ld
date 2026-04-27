_stack_size = 4K;

MEMORY
{
    SRAM (rwx) : ORIGIN = 0x80000000, LENGTH = 64K
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
        _etext = .;
    } > SRAM

    .data : AT(ADDR(.text) + SIZEOF(.text))
    {
        _data = .;
        *(.data*)
        *(.sdata*)
        _edata = .;
    } > SRAM

    .bss : AT(ADDR(.data) + SIZEOF(.data))
    {
        _bss = .;
        *(.bss*)
        *(COMMON)
        _ebss = .;
    } > SRAM

    .sbss : AT(ADDR(.bss) + SIZEOF(.bss))
    {
        _sbss = .;
        *(.sbss*)
        _esbss = .;
    } > SRAM

    _heap_bottom = .;
    _heap_top = ORIGIN(SRAM) + LENGTH(SRAM) - _stack_size;

    _stack_bottom = _heap_top;
    _stack_top = ORIGIN(SRAM) + LENGTH(SRAM);

}


