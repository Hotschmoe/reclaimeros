.section .text.boot
   .global _start

   _start:
       // Set up the stack pointer (SP)
       ldr x0, =0x40000000  // Use a high memory address for stack
       mov sp, x0

       // Jump to the kernel entry point
       ldr x0, =0x400000
       br x0

   // Ensure the ROM is 64KB aligned as some QEMU versions expect this
   .align 16