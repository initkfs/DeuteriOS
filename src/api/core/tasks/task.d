/**
 * Authors: initkfs
 */
module api.core.tasks.task;

import api.core.io.cstdio;

import Syslog = api.core.log.syslog;
import Critical = api.core.tasks.critical;
import ComContext = api.arch.riscv.hal.context;

import ldc.attributes;
import ldc.llvmasm;

alias SignalSet = uint;

enum taskMaxCount = 16;
enum taskStacksSize = 2048;

alias reg_t = size_t;

extern (C) struct RegContext
{
    reg_t ra; // 0/0
    reg_t sp; // 4/8
    reg_t gp; // 8/16
    reg_t tp; // 12/24

    reg_t s0; // 16/32
    reg_t s1; // 20/40
    reg_t s2; // 24/48
    reg_t s3; // 28/56
    reg_t s4; // 32/64
    reg_t s5; // 36/72
    reg_t s6; // 40/80
    reg_t s7; // 44/88
    reg_t s8; // 48/96
    reg_t s9; // 52/104
    reg_t s10; // 56/112
    reg_t s11; // 60/120

    reg_t a0; // 64/128
    reg_t a1; // 68/136
    reg_t a2; // 72/144
    reg_t a3; // 76/152
    reg_t a4; // 80/160
    reg_t a5; // 84/168
    reg_t a6; // 88/176
    reg_t a7; // 92/184

    reg_t t0; // 96/192
    reg_t t1; // 100/200
    reg_t t2; // 104/208
    reg_t t3; // 108/216
    reg_t t4; // 112/224
    reg_t t5; // 116/232
    reg_t t6; // 120/240

    reg_t mepc; // 124/248
}

//static assert(RegContext.sizeof == (14 * size_t.sizeof), "Wrong context size");

enum TaskState
{
    none,
    ready,
    running,
    sleep,
    waitSignal,
    //need reset
    killed,
    completed
}

struct Task
{
    RegContext context;

    TaskState state;
    string name;
    size_t sheduleCount;
    uint signals;
    int eventFlags;
    int waitEvents;
    uint yieldСount;

    SignalSet pendingSignals;
    SignalSet waitingMask;
    SignalSet handledSignals;
    void function()[uint.sizeof * 8] signalHandlers;
}

extern (C) __gshared
{
    ubyte[taskStacksSize][taskMaxCount] taskStacks;
    Task[taskMaxCount] tasks;

    Task osTask;
    bool isInitOsTask;
    Task* osTaskPtr;
    Task* currentTask;
    Task* firstTask;
    size_t taskIndex;

    size_t taskCount;
}

extern (C) __gshared taskContextOffset = 0;

private
{
    extern (C) void m_wait();
}

void initSheduler()
{
    osTask.name = "IDLE";
}

//TODO first call
bool isOsTask() => currentTask is &osTask;

void checkOsTask()
{
    assert(isOsTask, "The current task is not an IDLE task.");
}

size_t taskCreate(void function() t, string name)
{
    auto i = taskCount;
    assert(i < tasks.length);

    Task* taskPtr = &tasks[i];
    assert(taskPtr.state == TaskState.none);

    taskPtr.name = name;

    assert(taskPtr.context.ra == 0);
    assert(taskPtr.context.sp == 0);

    taskPtr.state = TaskState.ready;
    taskPtr.context.ra = cast(reg_t) t;
    taskPtr.context.mepc = taskPtr.context.ra;
    taskPtr.context.sp = cast(reg_t)&(taskStacks[i][taskStacksSize - 16]);
    taskPtr.context.sp = taskPtr.context.sp & ~0xF;

    signalsInit(taskPtr);

    taskCount++;

    //TODO remove
    if (!osTaskPtr)
    {
        osTaskPtr = &osTask;
    }

    if (i == 0)
    {
        firstTask = taskPtr;
    }

    return i;
}

void switchToFirstTask()
{
    assert(taskCount >= 1);
    switchToTask(&tasks[0]);
}

extern (C) void switchToTask(Task* task)
{
    assert(task);

    Critical.startCritical;

    currentTask = task;
    //assert(currentTask.state != TaskState.running);
    currentTask.state = TaskState.running;
    osTask.state = TaskState.sleep;

    Critical.endCritical;

    showContext(&tasks[0].context);
    ComContext.saveContext(cast(size_t*) &(osTask.context));
    ComContext.loadContext(cast(size_t*)&(currentTask.context));
    //context_switch(&(osTask.context), &(currentTask.context));
}

extern (C) void showContext(RegContext* ctx)
{
    RegContext context = *ctx;
    return;
}

bool hasStateTask(TaskState state)
{
    Critical.startCritical;
    scope (exit)
    {
        Critical.endCritical;
    }

    foreach (ti; 0 .. taskCount)
    {
        Task* task = &tasks[ti];
        if (task == currentTask)
        {
            continue;
        }

        if (task.state == state)
        {
            return true;
        }
    }
    return false;
}

bool hasReadyTasks() => hasStateTask(TaskState.ready);

protected void roundrobin()
{
    Task* next;
    size_t attempts;

    while (attempts < taskCount)
    {
        if (taskIndex >= taskCount)
        {
            taskIndex = 0;
        }

        Task* mustBeNext = &tasks[taskIndex];
        taskIndex++;

        if ((mustBeNext.state == TaskState.waitSignal) &&
            (mustBeNext.pendingSignals & mustBeNext.waitingMask))
        {
            mustBeNext.state = TaskState.ready;
        }

        if (mustBeNext.state == TaskState.ready)
        {
            next = mustBeNext;
            break;
        }
        attempts++;
    }

    if (next)
    {
        switchToTask(next);
        return;
    }

    m_wait();
}

extern (C) void roundrobinChoose()
{
    Task* next;
    size_t attempts;

    while (attempts < taskCount)
    {
        if (taskIndex >= taskCount)
        {
            taskIndex = 0;
        }

        Task* mustBeNext = &tasks[taskIndex];
        taskIndex++;

        // if ((mustBeNext.state == TaskState.waitSignal) &&
        //     (mustBeNext.pendingSignals & mustBeNext.waitingMask))
        // {
        //     mustBeNext.state = TaskState.ready;
        // }

        // if (mustBeNext.state == TaskState.ready)
        // {
        //     next = mustBeNext;
        //     break;
        // }
        //attempts++;
        currentTask = mustBeNext;
        break;
    }

    // if (next)
    // {
    //     currentTask = next;
    // }
}

void step()
{
    Syslog.trace("Run sheduler step");
    roundrobin;
}

void yield()
{
    switchToOs;
}

extern (C) void saveCurrentTask()
{
    ComContext.saveContext(cast(size_t*) &currentTask.context);
}

extern (C) void loadCurrentTask()
{
    ComContext.loadContext(cast(size_t*) &currentTask.context);
}

extern (C) void switchToOs() @naked
{
    __asm(
        "
    li t0, 1 << 3
    csrc mstatus, t0
    la t0, firstTask
    lw t0, 0(t0) 
    #la t1, taskContextOffset
    #lw t1, 0(t1)
    #add t0, t0, t1 

    sw ra, 0(t0)
    sw sp, 4(t0)
    sw s0, 8(t0)
    sw s1, 12(t0)
    sw s2, 16(t0)
    sw s3, 20(t0)
    sw s4, 24(t0)
    sw s5, 28(t0)
    sw s6, 32(t0)
    sw s7, 36(t0)
    sw s8, 40(t0)
    sw s9, 44(t0)
    sw s10, 48(t0)
    sw s11, 52(t0)

    la t0, osTaskPtr
    lw t0, 0(t0)
    la t1, currentTask
    sw t0, 0(t1)
    
    la t0, currentTask
    lw t0, 0(t0) 
    #la t1, taskContextOffset
    #lw t1, 0(t1)
    #add t0, t0, t1 

    lw s11, 52(t0)
    lw s10, 48(t0)
    lw s9, 44(t0)
    lw s8, 40(t0)
    lw s7, 36(t0)
    lw s6, 32(t0)
    lw s5, 28(t0)
    lw s4, 24(t0)
    lw s3, 20(t0)
    lw s2, 16(t0)
    lw s1, 12(t0)
    lw s0, 8(t0)
    lw sp, 4(t0)
    lw ra, 0(t0)

    ret
    ",
        "~{memory}"
    );

    //context_save_task(&currentTask.context);

    //Critical.startCritical;

    // auto oldTask = currentTask;
    // if (oldTask.state == TaskState.running)
    // {
    //     oldTask.state = TaskState.ready;
    // }

    //currentTask = &osTask;
    //assert(currentTask.state == TaskState.sleep);
    //currentTask.state = TaskState.running;
    //currentTask.yieldСount++;

    //context_load_task(&currentTask.context);
}

SignalSet signalWait(SignalSet waitmask)
{
    assert(currentTask);

    Critical.startCritical;

    if (currentTask.pendingSignals & waitmask)
    {
        SignalSet received = currentTask.pendingSignals & waitmask;
        currentTask.pendingSignals &= ~received;
        return received;
    }

    currentTask.state = TaskState.waitSignal;
    currentTask.waitingMask = waitmask;

    Critical.endCritical;

    yield;

    SignalSet received = currentTask.pendingSignals & waitmask;
    currentTask.pendingSignals &= ~received;

    callSignalHandlers(received);

    return received;
}

void addSignalHandler(void function() handler, uint mask)
{
    assert(currentTask);
    assert(mask > 0);
    assert((mask & (mask - 1)) == 0, "Invalid mask");

    Critical.startCritical;
    scope (exit)
    {
        Critical.endCritical;
    }

    //TODO more optimal
    foreach (hi; 0 .. currentTask.signalHandlers.length)
    {
        if (mask & (1u << hi))
        {
            currentTask.signalHandlers[hi] = handler;
            break;
        }
    }
}

protected void callSignalHandlers(uint mask)
{
    Critical.startCritical;
    scope (exit)
    {
        Critical.endCritical;
    }

    foreach (si; 0 .. currentTask.signalHandlers.length)
    {
        if ((mask & (1UL << si)) && currentTask.signalHandlers[si])
        {
            currentTask.signalHandlers[si]();
        }
    }
}

protected bool signalsInit(Task* task)
{
    assert(task);
    task.pendingSignals = 0;
    task.waitingMask = 0;
    task.handledSignals = 0;
    task.signalHandlers[] = null;
    return true;
}

bool signalSend(size_t tid, ubyte signal)
{
    Critical.startCritical;
    scope (exit)
    {
        Critical.endCritical;
    }

    assert(tid < taskCount);

    Task* targetTask = &tasks[tid];
    if (!targetTask || targetTask == currentTask)
    {
        return false;
    }

    targetTask.pendingSignals |= (1u << signal);
    return true;
}
