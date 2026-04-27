OUTPUT_ARCH( "riscv" )
ENTRY( _start )


MEMORY
{
    SRAM (rwx) : ORIGIN = 0x80000000, LENGTH = 64K
}

SECTIONS
{
    _ram_start = .;
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
        *(.srodata .srodata.*)
        _edata = .;
    } > SRAM

    .bss : AT(ADDR(.data) + SIZEOF(.data))
    {
        _bss = .;
        *(.bss*)
        _ebss = .;
        _sbss = .;
        *(.sbss*)
        _esbss = .;
    } > SRAM

    _heap_bottom = .;
    _heap_top = ORIGIN(SRAM) + LENGTH(SRAM) - __stack_size;

    _stack_bottom = _heap_top;
    _stack_top = ORIGIN(SRAM) + LENGTH(SRAM);
}


