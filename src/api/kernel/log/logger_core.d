/**
 * Authors: initkfs
 */
module api.kernel.log.logger_core;

enum LogLevel
{
    all,
    trace,
    info,
    warn,
    error
}

string getLevelName(const LogLevel level) @nogc nothrow pure @safe
{
    string levelName = "undefined.level";

    import std.traits: EnumMembers;

    foreach (l; EnumMembers!LogLevel)
    {
        if (level == l)
        {
            levelName = l.stringof;
            break;
        }
    }
    return levelName;
}

//minimal logger level >= global logger level
bool isForLogLevel(const LogLevel level, const LogLevel loggerLevel) @nogc nothrow pure @safe
{
    if (loggerLevel == LogLevel.all)
    {
        return true;
    }

    return level >= loggerLevel;
}
