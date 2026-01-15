module api.arch.riscv.boards.com.com_cpu;

/**
 * Authors: initkfs
 */
import ldc.llvmasm;

__gshared
{
    size_t __riscv_xlen;

    bool isMultiplyDivide;
    bool isAtomic;
    bool isFloat;
    bool isDouble;
    bool isCompressed;
    bool isBaseInteger;
    bool isUserMode;
}

size_t mhartId() @trusted => __asm!size_t("csrr $0, mhartid", "=r");

size_t m_get_misa() @trusted => __asm!size_t("csrr $0, misa", "=r");
size_t m_get_mvendorid() @trusted => __asm!size_t("csrr $0, mvendorid", "=r");
size_t m_get_marchid() @trusted => __asm!size_t("csrr $0, marchid", "=r");
size_t m_get_mimpid() @trusted => __asm!size_t("csrr $0, mimpid", "=r");

void wfi(){
    __asm("wfi", "");
}

void loadMisa()
{
    size_t misa = m_get_misa();

    if (misa == 0)
    {
        return;
    }

    version (Riscv64)
    {
        ubyte shift = 62;
    }
    else version (Riscv32)
    {
        ubyte shift = 30;
    }
    else
    {
        static assert(false, "Unsupported platform");
    }

    ubyte mxl = (misa >> shift) & 0x3; // RV64 (RV32 >> 30), & 0b11 two bits isolation
    switch (mxl)
    {
        case 1:
            __riscv_xlen = 32;
            break;
        case 2:
            __riscv_xlen = 64;
            break;
        default:
            break;
    }

    if (misa & (1 << ('M' - 'A')))
        isMultiplyDivide = true; //Multiply/Divide
    if (misa & (1 << ('A' - 'A')))
        isAtomic = true; //Atomic
    if (misa & (1 << ('F' - 'A')))
        isFloat = true; // Float
    if (misa & (1 << ('D' - 'A')))
        isDouble = true; //Double
    if (misa & (1 << ('C' - 'A')))
        isCompressed = true; //Compressed;
    if (misa & (1 << ('I' - 'A')))
        isBaseInteger = true; //Base Integer;
    if (misa & (1 << ('U' - 'A')))
        isUserMode = true; //User mode;
}

string vendorId()
{
    auto id = m_get_mvendorid();
    if (id == 0)
    {
        return "";
    }

    //JEDEC
    //ubyte bank = (mvendorid) & 0x7F; //0-6
    //ubyte id = (mvendorid >> 7) & 0x7F; //7-13

    switch (id)
    {
        case 0x00000531:
            return "SiFive";
            break;
        case 0x000005B6:
            return "Andes Technology";
            break;
        case 0x000005A7:
            return "Alibaba/T-Head";
            break;
        default:
            break;
    }

    return "Unknown";
}