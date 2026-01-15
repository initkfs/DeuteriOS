/**
 * Authors: initkfs
 */
module api.kernel.mem.allocs.allocator;

import api.kernel.mem.unique_ptr : UniqPtr;

alias AllocFuncType = void* function(size_t sizeBytes) @nogc nothrow @trusted;
alias CallocFuncType = void* function(size_t capacity, size_t sizeBytes) @nogc nothrow @trusted;
alias FreeFuncType = bool function(void* ptr) @nogc nothrow @trusted;

private __gshared
{
    void* _heapStartAddr;
    void* _heapEndAddr;
}

__gshared
{
    AllocFuncType allocFunc;
    CallocFuncType callocFunc;
    FreeFuncType freeFunc;
}

UniqPtr!T uptr(T)(size_t capacity = 1) @nogc nothrow @safe
{
    assert(allocFunc);
    assert(freeFunc);
    assert(capacity > 0, "Pointer capacity must be positive number");

    import MathStrict = api.kstd.math.math_strict;

    size_t sizeInBytes;
    assert(multiplyExact(capacity, T.sizeof, sizeInBytes), "Capacity overflow");
    assert(sizeInBytes >= T.sizeof);
    void* newPtr = allocFunc(sizeInBytes);

    assert(newPtr, "Allocated pointer is null");

    return UniqPtr!T(cast(T*) newPtr, sizeInBytes, capacity, freeFunc);
}

void heapStartAddr(void* ptr) @nogc nothrow
{
    assert(ptr, "Heap start address must not be null");
    _heapStartAddr = ptr;
}

void* heapStartAddr() @nogc nothrow
{
    assert(_heapStartAddr, "Heap start address is null");
    return _heapStartAddr;
}

void heapEndAddr(void* ptr) @nogc nothrow
{
    assert(ptr, "Heap end address must not be null");
    _heapEndAddr = ptr;
}

void* heapEndAddr() @nogc nothrow
{
    assert(_heapEndAddr, "Heap end address is null");
    return _heapEndAddr;
}
