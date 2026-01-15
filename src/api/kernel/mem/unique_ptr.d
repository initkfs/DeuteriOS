/**
 * Authors: initkfs
 */
module api.kernel.mem.unique_ptr;

import api.kernel.mem.allocs.allocator : FreeFuncType;

import api.kernel.errors;

struct UniqPtr(T, FreeFunc = FreeFuncType)
{
    private
    {
        T* _ptr;
        size_t _sizeInBytes;
        size_t _capacity;
        bool _freed;
        FreeFunc _freeFunPtr;
    }

    bool isAutoFree;

    this(T* t, size_t sizeBytes, bool isAutoFree = true, FreeFunc freeFunPtr = null) @nogc nothrow pure @safe
    {
        static assert(T.sizeof > 0);
        assert(sizeBytes > 0);
        assert(sizeBytes >= T.sizeof);

        _ptr = t;
        _sizeInBytes = sizeBytes;
        _capacity = sizeBytes / T.sizeof;
        assert(_capacity > 0);

        this._freeFunPtr = freeFunPtr;
        this.isAutoFree = isAutoFree;
    }

    alias value this;

@nogc nothrow:

    @disable this(ref return scope UniqPtr!T rhs) pure
    {
    }

    ~this() @safe
    {
        if (isAutoFree)
        {
            free;
        }
    }

    bool isFreed() const pure @safe
    {
        return _freed;
    }

    void free() @safe
    in (_ptr)
    in (_freeFunPtr)
    {
        assert(!_freed, "Memory pointer has already been freed");

        bool isFreed = _freeFunPtr(_ptr);
        assert(isFreed, "Memory pointer not deallocated correctly");

        //TODO reset capacity\size
        _ptr = null;
        _freed = true;
    }

    void release() @safe
    in (!_freed)
    {
        _ptr = null;
        _freed = false;

        _sizeInBytes = 0;
        _capacity = 0;
        _freeFunPtr = null;
    }

    protected inout(T*) indexUnsafe(size_t i) inout return @trusted
    in (_ptr)
    in (!_freed)
    {
        assert(i < capacity, "Index is out of bounds");
        return &_ptr[i];
    }

    protected inout(T*) index(size_t i) inout return @safe
    {
        return indexUnsafe(i);
    }

    inout(T) opIndex(size_t i) inout @safe
    {
        return *(index(i));
    }

    inout(T) value() inout @safe
    {
        return opIndex(0);
    }

    void value(T newValue) @safe
    {
        *index(0) = newValue;
    }

    inout(T*) ptr() inout return @safe
    in (_ptr)
    in (!_freed)
    {
        return _ptr;
    }

    inout(T*) ptrUnsafe() inout
    in (_ptr)
    in (!_freed)
    {
        return _ptr;
    }

    // a[i] = v
    void opIndexAssign(T value, size_t i) @safe
    {
        *(index(i)) = value;
    }

    // a[i1, i2] = v
    void opIndexAssign(T value, size_t i1, size_t i2) @safe
    {

        opSlice(i1, i2)[] = value;
    }

    void opIndexAssign(T[] value, size_t i1, size_t i2) @safe
    {
        opSlice(i1, i2)[] = value;
    }

    inout(T[]) opSlice(size_t i, size_t j) @trusted inout
    in (_ptr)
    in (!_freed)
    {
        assert(i < j);
        assert(j <= capacity);
        return _ptr[i .. j];
    }

    void opAssign(T newVal) @safe
    {
        value(newVal);
    }

    void opAssign(UniqPtr!T newPtr) @safe
    {
        if (_ptr)
        {
            free;
        }

        _freed = false;

        _ptr = newPtr.ptrUnsafe;
        assert(_ptr);

        _freeFunPtr = newPtr.freeFunPtr;
    }

    size_t sizeBytes() const @safe
    {
        return _sizeInBytes;
    }

    size_t capacity() const @safe
    {
        return _capacity;
    }

    FreeFunc freeFunPtr() const @safe
    in (_freeFunPtr)
    {
        return _freeFunPtr;
    }

    auto range() return scope @safe
    {
        static struct PtrRange
        {
            private
            {
                T* ptr;
                size_t capacity;
                size_t currentIndex;
            }

            this(T* newPtr, size_t capacity)
            {
                this.ptr = newPtr;
                this.capacity = capacity;
            }

            bool empty() const
            {
                return currentIndex >= capacity;
            }

            inout(T) front() inout
            {
                return ptr[currentIndex];
            }

            void popFront()
            {
                currentIndex++;
            }
        }

        return PtrRange(_ptr, capacity);
    }
}

unittest
{
    int value = 45;
    auto ptr = UniqPtr!(int)(&value, value.sizeof, isAutoFree:
        false);

    assert(!ptr.isFreed, "Pointer freed");
    assert(ptr.sizeBytes == value.sizeof, "Pointer invalid size");

    assert(ptr.value == value, "Pointer value incorrect");
    assert(ptr[0] == value, "Pointer first index incorrect");
    assert(ptr.ptr == &value, "Invalid raw pointer");

    enum newValue = 2324;
    ptr.value = newValue;
    assert(ptr.value == newValue, "Pointer invalid new value");

    int[2] arr = [54, 65];
    auto ptr2 = UniqPtr!(int)(arr.ptr, arr.sizeof, isAutoFree:
        false);

    auto ptr2Slice = ptr2[0 .. 2];
    assert(ptr2Slice == arr);

    int[2] arrZero = [0, 0];
    ptr2[0 .. 2][] = 0;
    assert(ptr2[0 .. 2] == arrZero);

    int[2] arr3 = [43, 43];
    ptr2[0, 2] = 43;
    assert(ptr2[0 .. 2] == arr3);

    int[2] arr34 = [23, 34];
    ptr2[0, 2] = arr34[];
    assert(ptr2[0 .. 2] == arr34);

    size_t iters;
    foreach (v; ptr2.range)
    {
        switch (iters)
        {
            case 0:
                assert(v == 23);
                break;
            case 1:
                assert(v == 34);
                break;
            default:
                break;
        }
        iters++;
    }
    assert(iters == 2);
}
