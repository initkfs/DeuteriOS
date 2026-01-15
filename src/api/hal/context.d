/**
 * Authors: initkfs
 */
module api.hal.context;

import api.arch.riscv.versions;

static if (__isRiscv)
{
    public import api.arch.riscv.boards.com.com_context;
}
else
{
    static assert(false, "Not supported HAL context for platform");
}
