module api.arch.riscv.hal.atomic;

public import api.arch.riscv.hal.boards.com.com_atomic;

unittest
{
    size_t v = 12;
    auto res = cas(&v, 12, 22);
    assert(res);
    assert(v == 22);

    size_t v1 = 12;
    assert(!cas(&v1, 24, 22));
}