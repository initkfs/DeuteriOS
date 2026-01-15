module api.arch.riscv.versions;

version (Riscv32)
{
    enum __isRiscv = true;
}

version (Riscv64)
{
    enum __isRiscv = true;
}
