/**
 * Authors: initkfs
 */
module api.arch.riscv.hal.interrupts;

public import api.arch.riscv.hal.boards.com.com_interrupts_constants;
public import api.arch.riscv.hal.boards.com.com_interrupts;

version (Qemu)
{
    public import api.arch.riscv.hal.boards.qemu.qemu_interrupts_constants;
}
else
{
    static assert(false, "Not supported board");
}

ulong mTimeRegCmpAddr(size_t hartid) @trusted
{
    return clintBase + clintCompareRegHurtOffset + clintMtimecmpSize * hartid;
}

ulong mTime() @trusted => clintBase + clintTimerRegOffset;
