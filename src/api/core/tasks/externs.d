/**
 * Authors: initkfs
 */
module api.core.tasks.externs;

extern (C) @trusted:

version (Riscv32)
{
    //if(*ptr == expected){
    //  *ptr = desired;
    //  return true;
    //} 
    //return false
    size_t cas_lrsc(scope uint* addr, int expectedInAddr, int newValueIfAddrEqvExpected);
}

version (Riscv64)
{
    size_t cas_lrsc(scope size_t* addr, size_t expected, size_t desired);

    size_t swap_acquire(scope size_t* lockPtr);
    size_t swap_release(scope size_t* lockPtr);
}
