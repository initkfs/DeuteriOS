/**
 * Authors: initkfs
 */
module api.kernel;

//Entry point
import api.hal.entry;

import Tests = api.core.tests;
import Syslog = api.core.log.syslog;
import BlockAllocator = api.core.mem.allocs.block_allocator;
import MemCore = api.core.mem.mem_core;
import UPtr = api.core.mem.unique_ptr;
import StackStrMod = api.cstd.strings.stack_str;
import Allocator = api.core.mem.allocs.allocator;
import Str = api.core.strings.str;
import Hash = api.core.strings.hash;
import MathCore = api.core.math.math_core;
import MathStrict = api.core.math.math_strict;
import MathRandom = api.core.math.math_random;
import Units = api.core.util.units;
import Bits = api.core.bits;
import Atomic = api.hal.atomic;
import Spinlock = api.core.tasks.sync.spinlock;
import Critical = api.core.tasks.critical;

version (FeatureFloatPoint)
{
    import MathFloat = api.core.math.math_float;
}
else
{
    //TODO placeholder
    import MathFloat = api.core.math.math_core;
}

import api.core.io.cstdio;
import api.core.tasks.task;
import api.core.timer;
import api.core.trap;

__gshared
{
    int sharedCounter;
    Spinlock.Lock lock;

    bool isTimer = true;
}

private void runTests()
{
    if (Syslog.isTraceLevel)
    {
        Syslog.trace("Start testing modules");
    }

    import std.meta : AliasSeq;

    alias testModules = AliasSeq!(
        MemCore,
        UPtr,
        Str,
        Hash,
        StackStrMod,
        MathCore,
        MathStrict,
        MathFloat,
        MathRandom,
        Bits,
        Units,
        Atomic,
        Spinlock
    );

    foreach (m; testModules)
    {
        Tests.runTest!(m);
    }

    if (Syslog.isTraceLevel)
    {
        Syslog.trace("End of testing modules");
    }
}

__gshared {
    size_t tid;
    size_t tid1;
    size_t tid2;
}

extern (C) void dstart()
{
    import Interrupts = api.hal.interrupts;

    Interrupts.mGlobalInterruptDisable;

    Syslog.setLoad(true);

    // ubyte* bssStart = cast(ubyte*) get_bss_start;
    // ubyte* bssEnd = cast(ubyte*) get_bss_end;

    // while (bssStart < bssEnd)
    // {
    //     //TODO volatile
    //     *bssStart++ = 0;
    // }

    Syslog.info("Os start");

    trapInit;
    Syslog.info("Init traps");

    // import MemoryHAL = api.hal.memory;

    // auto heapStartAddr = cast(void*)(MemoryHAL.get_heap_start);
    // auto heapEndAddr = cast(void*)(MemoryHAL.get_heap_end);

    // Allocator.heapStartAddr = heapStartAddr;
    // Allocator.heapEndAddr = heapEndAddr;

    // BlockAllocator.initialize(heapStartAddr, heapEndAddr);
    // Allocator.allocFunc = &BlockAllocator.alloc;
    // Allocator.callocFunc = &BlockAllocator.calloc;
    // Allocator.freeFunc = &BlockAllocator.free;

    runTests;

    initSheduler;

    Critical.startCritical;

    if (isTimer)
    {
        timerInit;
        Syslog.info("Init timers");
    }

    Critical.endCritical;

    tid = taskCreate(&task0, "task0");
    tid1 = taskCreate(&task1, "task1");
    //tid2 = taskCreate(&task2);

    //Interrupts.mGlobalInterruptEnable;

    int isContinue = 0x10203040;

    while (true)
    {
        Syslog.trace("Sheduler start step");
        assert(isContinue == 0x10203040);
        switchToFirstTask;
        //Syslog.trace("Sheduler end step");
    }
}

void task0()
{
    int isContinue = 0x10203040;
    Syslog.trace("Enter task0");
    
    while (true)
    {
        Syslog.trace("Start task0");
        //plop();
        //yield;
        assert(isContinue == 0x10203040);
        //yield;
        Syslog.trace("End task0");

        //addSignalHandler(&sigHandler1, 8);

        //signalWait(8);
        delayTicks;
    }
}

extern(C) void plop(){
}

void sigHandler1(){
    Syslog.trace("Signal 1");
}

void sigHandler2(){
    Syslog.trace("Signal 2");
}

void task1()
{
    Syslog.trace("Enter task1");
    int isContinue = 0x10203040;
    while (true)
    {
        Syslog.trace("Start task1");
        assert(isContinue == 0x10203040);
        //yield;
        //signalSend(tid, 3);
        Syslog.trace("End task1");

        delayTicks;
    }
}

void task2()
{
    Syslog.trace("Enable LED3.");
    while (true)
    {
        Syslog.trace("LED3 ON");
        delayTicks;
    }
}

void delayTicks(int count = 1000)
{
    long counter = count * 50000;
    while (counter--)
    {
    }
}
