ENTRY(_start)

SECTIONS
{
    . = 0x400000; /* Starting address for the kernel */

    .text : {
        *(.text._start) /* Entry point */
        *(.text*) /* All other text sections */
    }

    .rodata : {
        *(.rodata*) /* Read-only data */
    }

    .data : {
        *(.data*) /* Initialized data */
    }

    .bss : {
        *(.bss*) /* Uninitialized data */
        *(COMMON)
    }

    /DISCARD/ : { *(.note.GNU-stack) }
}
