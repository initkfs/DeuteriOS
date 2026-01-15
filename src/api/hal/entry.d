module api.hal.entry;

import api.arch.riscv.versions;

static if (__isRiscv)
{
    public import api.arch.riscv.boards.com.com_start;
}
else
{
    static assert(false, "Not supported HAL entry for platform");
}
