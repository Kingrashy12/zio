const ziglet = @import("ziglet");
const CommandContext = ziglet.CommandContext;
const Atomic = std.atomic.Value;
const Thread = std.Thread;
const std = @import("std");
const terminal = ziglet.utils.terminal;
const Color = terminal.Color;
const printColored = terminal.printColored;

pub fn updateCommand(ctx: CommandContext) !void {
    const allocator = ctx.allocator;
    var checking = Atomic(bool).init(true);

    const animation_thread = try Thread.spawn(.{}, animate, .{&checking});
    const check_thread = try Thread.spawn(.{}, checkUpdate, .{ &checking, allocator });

    check_thread.join();
    animation_thread.join();

    // this should be final print
}

fn animate(is_checking: *Atomic(bool)) void {
    const frames = [_][]const u8{ "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" };
    var frame_index: usize = 0;

    while (is_checking.load(.acquire)) {
        std.debug.print("\r{s}{s} Checking for updates...{s}", .{
            Color.ansiCode(.white),
            frames[frame_index % frames.len],
            Color.ansiCode(.reset),
        });
        std.Thread.sleep(100 * std.time.ns_per_ms);
        frame_index += 1;
    }
}

fn checkUpdate(is_checking: *Atomic(bool), allocator: std.mem.Allocator) void {

    // for now check the version in here
    var i: usize = 0;
    while (i < 1000_000_000) {
        i += 1;
    }

    is_checking.store(false, .release);

    const version_file = std.fs.cwd().openFile("version", .{}) catch |err| {
        printColored(.red, "Unable to open file:{s}\n", .{@errorName(err)});
        return;
    };

    var buffer: [6]u8 = undefined;

    _ = version_file.readAll(&buffer) catch |err| {
        printColored(.red, "Unable to read file:{s}\n", .{@errorName(err)});
        return;
    };

    const version = buffer[0..buffer.len];

    var child = std.process.Child.init(&.{ "zio", "-V" }, allocator);
    child.stdout_behavior = .Pipe;

    child.spawn() catch |err| {
        printColored(.red, "Unable to spawn child process:{s}\n", .{@errorName(err)});
        return;
    };

    var current_buffer: [50]u8 = undefined;

    var byte_read: usize = 0;

    if (child.stdout) |out| {
        const len = out.readAll(&current_buffer) catch |err| {
            printColored(.red, "Unable to read child process output:{s}\n", .{@errorName(err)});
            return;
        };
        byte_read = len;
    }

    _ = child.wait() catch {
        printColored(.red, "Unable to wait for child process\n", .{});
        return;
    };

    const values_to_strip = std.ascii.whitespace ++ "\x1b[0m" ++ "\x1b[37m";

    const current_version = std.mem.trim(u8, current_buffer[0..byte_read], values_to_strip);

    const is_updated = std.mem.eql(u8, version, current_version);

    if (is_updated) {
        printColored(.magenta, "\r🤗 zio is up to date!    \n", .{});
    } else {
        std.debug.print("\r{s}✓ Found update: {s}   {s}\n", .{
            Color.ansiCode(.green),
            version,
            Color.ansiCode(.reset),
        });
    }
}

fn install(installing: *Atomic(bool)) void {
    var i: usize = 0;
    while (i < 1000_000_000) {
        i += 1;
    }
    installing.store(false, .release);
}
