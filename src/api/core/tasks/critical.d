module api.core.tasks.critical;

version (RiscvGeneric)
{
    import Interrupts = api.arch.riscv.hal.interrupts;
}
else
{
    static assert(false, "Not supported platform");
}

/**
 * Authors: initkfs
 */

void startCritical()
{
    Interrupts.mGlobalInterruptDisable;
}

void endCritical()
{
    Interrupts.mGlobalInterruptEnable;
}
