/**
 * Authors: initkfs
 */
module api.kstd.bits;

import std.traits;

bool isBitSet(T)(T bits, T n) if (isUnsigned!T)
{
  return (bits & (1 << n)) != 0;
}

unittest
{
  assert(isBitSet(1u, 0u));
  assert(isBitSet(2u, 1u));
  assert(isBitSet(4u, 2u));
  assert(isBitSet(128u, 7u));
}

T setBit(T)(T bits, T n) if (isUnsigned!T)
{
  return bits | (1 << n);
}

unittest
{
  assert(setBit(0u, 0u) == 1u);
  assert(setBit(0u, 1u) == 2u);
  assert(setBit(0u, 4u) == 16u);
  assert(setBit(0u, 9u) == 512u);
  assert(setBit(128u, 3u) == 136u);
}

T unsetBit(T)(T bits, T n) if (isUnsigned!T)
{
  return bits & ~(1 << n);
}

unittest
{
  assert(unsetBit(3u, 0u) == 2u);
  assert(unsetBit(15u, 2u) == 11u);
}
