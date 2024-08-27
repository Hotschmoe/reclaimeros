pub fn delay(cycles: usize) void {
    var i: usize = 0;
    while (i < cycles) : (i += 1) {
        asm volatile ("" ::: "memory");
    }
}
