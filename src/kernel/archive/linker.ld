SECTIONS {
    . = 0x40000000;
    .text : ALIGN(2048) { /* Align to 2048 bytes for the exception vector table */
        KEEP(*(.text.exception_vector_table))
        *(.text)
    }
    .rodata : { *(.rodata) }
    .data : { *(.data) }
    .bss : { *(.bss COMMON) }
    . = ALIGN(8);
    . = . + 0x1000; /* 4kB of stack memory */
    stack_top = .;
}