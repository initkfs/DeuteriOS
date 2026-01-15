module api.core.tasks.critical;

import Interrupts = api.hal.interrupts;

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
