/**
 * Authors: initkfs
 */
module api.kernel.dev.uart;

import Ns16650a = api.kernel.dev.ns16550a;

void print(char c) @nogc nothrow
{
    Ns16650a.writeTx(c);
}

void print(const(char)[] s) @nogc nothrow
{
    foreach (c; s)
    {
        print(c);
    }
}

