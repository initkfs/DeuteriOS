/**
 * Authors: initkfs
 */
module api.hal.cpu;

import api.arch.riscv.versions;

static if (__isRiscv)
{
    public import api.arch.riscv.boards.com.com_cpu;
}
else
{
    static assert(false, "Not supported HAL cpu for platform");
}
