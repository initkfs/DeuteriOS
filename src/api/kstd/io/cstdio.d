/**
 * Authors: initkfs
 */
module api.kstd.io.cstdio;

import Uart = api.kernel.dev.uart;
import Ascii = api.kstd.strings.ascii;

@nogc nothrow:

void print(const char ch)
{
    Uart.print(ch);
}

void print(const(char)[] str)
{
    Uart.print(str);
}

void printa(Args...)(Args args) @nogc nothrow
{
    foreach (arg; args)
    {
        print(arg);
    }
}

void println(Args...)(Args args) @nogc nothrow
{
    printa(args, Ascii.LF);
}

void printz(const char* str)
{
    //TODO toStringz
}

void printlnz(const char* str)
{
    //TODO toStringz
}

void printSpace()
{
    print(' ');
}
