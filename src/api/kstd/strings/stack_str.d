/**
 * Authors: initkfs
 */
module api.cstd.strings.stack_str;

StackStr!(Len, T) makeStackStr(size_t Len = 128, T = char)(const(char)[] str = null)
{
    return StackStr!(Len, T)(str);
}

struct StackStr(size_t Len, T = char)
{
    private
    {
        T[Len] _buffer;
        size_t _length;
    }

    invariant
    {
        assert(_length <= _buffer.length, "String stack invariant: length must be less or equal than buffer");
    }

    this(const(char)[] str)
    {
        assert(str.length <= Len, "Stack string buffer overflow");
        _length = str.length;
        if (_length > 0)
        {
            _buffer[] = str;
        }
    }

    alias slice this;

    inout(T[]) slice() inout
    {
        return _buffer[0 .. _length];
    }

    inout(T[]) opSlice(size_t i, size_t j) inout
    {
        assert(i < j, "Start slice index must be less than end");
        assert(j <= _length, "End index overflow");
        return _buffer[i .. j];
    }

    inout(T[]) opSlice() inout
    {
        return slice;
    }

    void opIndexAssign(T value)
    {
        slice[] = value;
    }

    size_t length()
    {
        return _length;
    }

    void length(size_t value)
    {
        assert(value < Len, "Length value overflow");
        _length = value;
    }

    StackStr concat(T, size_t L = Len)(scope const(T)[] str2) @safe
    {
        auto newStr = makeStackStr!(L, T);
        immutable newLength = _length + str2.length;
        newStr.length = newLength;
        newStr[0 .. _length][] = slice;
        newStr[_length .. newLength][] = str2[];
        return newStr;
    }

    bool equals(scope const(T)[] str) @safe
    {
        if (str.length != _length)
        {
            return false;
        }

        foreach (i, v; slice)
        {
            if (v != str[i])
            {
                return false;
            }
        }
        return true;
    }
}

unittest
{
    enum str1 = "foo bar";
    auto str = makeStackStr(str1);
    assert(str1.length == str.length);
    assert(str.equals(str1));

    enum str2 = " baz";
    assert(str.concat(str2).equals("foo bar baz"));
}
