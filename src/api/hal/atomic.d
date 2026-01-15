module api.hal.atomic;

import api.arch.riscv.versions;

static if (__isRiscv)
{
    public import api.arch.riscv.boards.com.com_atomic;

    unittest
    {
        size_t v = 12;
        auto res = cas(&v, 12, 22);
        assert(res);
        assert(v == 22);

        size_t v1 = 12;
        assert(!cas(&v1, 24, 22));
    }
}
else
{
    static assert(false, "Not supported HAL atomics for platform");
}
