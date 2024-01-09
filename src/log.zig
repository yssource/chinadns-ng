const std = @import("std");
// const builtin = @import("builtin");
const c = @import("c.zig");
const C = @import("C.zig");
const SourceLocation = std.builtin.SourceLocation;

const Level = enum {
    Debug,
    Info,
    Warning,
    Error,
    Fatal,

    fn desc(level: Level) [:0]const u8 {
        return switch (level) {
            .Debug => "D",
            .Info => "I",
            .Warning => "W",
            .Error => "E",
            .Fatal => "F",
        };
    }

    fn color(level: Level) [:0]const u8 {
        return switch (level) {
            .Debug => "34",
            .Info => "32",
            .Warning => "33",
            .Error => "35",
            .Fatal => "31",
        };
    }
};

/// year, month, day, hour, min, sec
fn time() [6]c_int {
    const tm = C.localtime(C.time()).?;
    return .{ tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday, tm.tm_hour, tm.tm_min, tm.tm_sec };
}

pub fn srcinfo(comptime src: SourceLocation, fn_name_only: bool) [:0]const u8 {
    const filename = b: {
        // remove directories from path
        // can't use std.mem.lastIndexOfScalar because of compiler bugs
        var i = src.file.len - 1;
        while (i >= 0) : (i -= 1)
            if (src.file[i] == '/') break;
        break :b src.file[i + 1 ..];
    };
    const fn_name = b: {
        // remove top-level namespace (filename)
        const i = std.mem.indexOfScalar(u8, src.fn_name, '.') orelse -1;
        break :b src.fn_name[i + 1 ..];
    };
    if (fn_name_only)
        return "[" ++ fn_name ++ "]";
    return std.fmt.comptimePrint("[{s}:{d} {s}]", .{ filename, src.line, fn_name });
}

fn log_write(comptime level: Level, comptime src: SourceLocation, comptime in_fmt: [:0]const u8, in_args: anytype) void {
    const timefmt = "%d-%02d-%02d %02d:%02d:%02d";
    const prefix = "\x1b[" ++ level.color() ++ ";1m" ++ timefmt ++ " " ++ level.desc() ++ "\x1b[0m \x1b[1m" ++ srcinfo(src, false) ++ "\x1b[0m";
    const fmt = prefix ++ " " ++ in_fmt ++ "\n";
    const t = time();
    const args = .{ t[0], t[1], t[2], t[3], t[4], t[5] } ++ in_args;
    @call(.{}, C.printf, .{ fmt, args });
}

/// enabled for debug build only
pub fn debug(comptime src: SourceLocation, comptime fmt: [:0]const u8, args: anytype) void {
    // if (comptime builtin.mode == .Debug)
    return log_write(.Debug, src, fmt, args);
}

pub fn info(comptime src: SourceLocation, comptime fmt: [:0]const u8, args: anytype) void {
    return log_write(.Info, src, fmt, args);
}

pub fn warn(comptime src: SourceLocation, comptime fmt: [:0]const u8, args: anytype) void {
    return log_write(.Warning, src, fmt, args);
}

pub fn err(comptime src: SourceLocation, comptime fmt: [:0]const u8, args: anytype) void {
    return log_write(.Error, src, fmt, args);
}

pub fn fatal(comptime src: SourceLocation, comptime fmt: [:0]const u8, args: anytype) noreturn {
    log_write(.Fatal, src, fmt, args);
    _ = C.fflush(null);
    c.abort();
}

pub fn @"test: logging"() !void {
    if (C.getenv("TEST_LOGGING") == null) return;
    test_logging();
}

fn test_logging() void {
    debug(@src(), "hello, %s", .{"world"});
    debug(@src(), "hello, %s", .{"world"});
    debug(@src(), "hello, %s", .{"world"});
    info(@src(), "hello, %s", .{"world"});
    info(@src(), "hello, %s", .{"world"});
    info(@src(), "hello, %s", .{"world"});
    warn(@src(), "hello, %s", .{"world"});
    warn(@src(), "hello, %s", .{"world"});
    warn(@src(), "hello, %s", .{"world"});
    err(@src(), "hello, %s", .{"world"});
    err(@src(), "hello, %s", .{"world"});
    err(@src(), "hello, %s", .{"world"});
    // fatal(@src(), "hello, %s", .{"world"});

    foo.test_logging();
}

const foo = struct {
    fn test_logging() void {
        debug(@src(), "hello, %s", .{"world"});
        debug(@src(), "hello, %s", .{"world"});
        debug(@src(), "hello, %s", .{"world"});
        info(@src(), "hello, %s", .{"world"});
        info(@src(), "hello, %s", .{"world"});
        info(@src(), "hello, %s", .{"world"});
        warn(@src(), "hello, %s", .{"world"});
        warn(@src(), "hello, %s", .{"world"});
        warn(@src(), "hello, %s", .{"world"});
        err(@src(), "hello, %s", .{"world"});
        err(@src(), "hello, %s", .{"world"});
        err(@src(), "hello, %s", .{"world"});
        // fatal(@src(), "hello, %s", .{"world"});

        bar.test_logging();
    }

    const bar = struct {
        fn test_logging() void {
            debug(@src(), "hello, %s", .{"world"});
            debug(@src(), "hello, %s", .{"world"});
            debug(@src(), "hello, %s", .{"world"});
            info(@src(), "hello, %s", .{"world"});
            info(@src(), "hello, %s", .{"world"});
            info(@src(), "hello, %s", .{"world"});
            warn(@src(), "hello, %s", .{"world"});
            warn(@src(), "hello, %s", .{"world"});
            warn(@src(), "hello, %s", .{"world"});
            err(@src(), "hello, %s", .{"world"});
            err(@src(), "hello, %s", .{"world"});
            err(@src(), "hello, %s", .{"world"});
            // fatal(@src(), "hello, %s", .{"world"});
        }
    };
};