module api.arch.riscv.hal.memory;

public import api.arch.riscv.hal.boards.com.com_memory;

size_t _heap_start;
size_t _heap_end;

size_t get_heap_start()
{
    return _heap_start;
}

size_t get_heap_end()
{
    return _heap_end;
}