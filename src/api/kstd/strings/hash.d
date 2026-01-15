/**
 * Authors: initkfs
 */
module api.kstd.strings.hash;

uint jenkins(const char[] str)
{
    uint hash;
    foreach (ch; str)
    {
        hash += ch;
        hash += hash << 10;
        hash ^= hash >> 6;
    }
    hash += hash << 3;
    hash ^= hash >> 11;
    hash += hash << 15;
    return hash;
}

unittest
{
    enum str = "The quick brown fox jumps over the lazy dog";
    assert(jenkins(str) == 1369346549);
}

uint adler32(const char[] str)
{
    enum uint modAdler = 65521;
    uint a = 1, b;
    foreach (ubyte ch; str)
    {
        a = (a + ch) % modAdler;
        b = (b + a) % modAdler;
    }
    return (b << 16) | a;
}

unittest
{
    enum str = "The quick brown fox jumps over the lazy dog";
    assert(adler32(str) == 0x5bdc0fda);
}

/** 
 * See https://maskray.me/blog/2023-04-12-elf-hash-function
 */
ulong elfhash(const char[] str)
{
    ulong hash;
    foreach (ubyte ch; str)
    {
        hash = (hash << 4) + ch;
        auto hi = hash & 0xf0000000;
        if (hi != 0)
        {
            hash ^= hi >> 24;
            hash ^= hi;
        }
    }
    return hash;
}

unittest
{
    enum s = "The quick brown fox jumps over the lazy dog";
    assert(elfhash(s) == 0x04280c57);
}

uint djb2(const char[] str)
{
    uint hash = 5381;
    foreach (ubyte ch; str)
    {
        //hash = hash * 33 + ch
        hash = ch + hash * 33;
    }

    return hash;
}

unittest
{
    enum s = "The quick brown fox jumps over the lazy dog";
    assert(djb2(s) == 0x34cc38de);
}

uint krhash(const char[] str)
{
    uint hash;

    foreach (ubyte ch; str)
    {
        hash = ch + hash * 31;
    }

    return hash;
}

unittest
{
    enum s = "The quick brown fox jumps over the lazy dog";
    assert(krhash(s) == 0xdbacdd53);
}
