module api.kernel.mem.canary;

//TODO random
extern (C) __gshared uint __stack_chk_guard = 0x0ADBEEF;

extern (C) void __stack_chk_fail()
{
    import api.kernel.errors;

    panic("Canary");
}

void initcan()
{
    //TODO
}

//| localvars | canary | saved RBP | ret |
/** 
   mixin(CanaryDecl)
   char buffer[16];
   strcpy(buffer, input);
 */
enum CanaryDecl = q{
    const __canary = __stack_chk_guard;
    scope(exit) if (__canary != __stack_chk_guard) __stack_chk_fail();
};
