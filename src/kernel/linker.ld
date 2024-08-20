ENTRY(_start)

SECTIONS {
    . = 0x40000000;  /* Typical load address for ARM */

    .text : ALIGN(4K) {
        *(.text.boot)  /* Boot code section */
        *(.text*)
    }

    .rodata : ALIGN(4K) {
        *(.rodata*)
    }

    .data : ALIGN(4K) {
        *(.data*)
    }

    .bss : ALIGN(4K) {
        *(COMMON)
        *(.bss*)
    }
}