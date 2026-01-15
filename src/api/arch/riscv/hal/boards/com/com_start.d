module api.arch.riscv.hal.boards.com.com_start;

import ldc.llvmasm;
import ldc.attributes;

extern (C) __gshared:

void _start() @naked @optStrategy("none") @section(".text.init")
{
    __asm("
    csrr a0, mhartid
    bnez a0, _hlt
    la sp, _stack_start
    call dstart
_hlt:
    wfi
    j _hlt
    ", "");
}
