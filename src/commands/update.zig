const ziglet = @import("ziglet");
const CommandContext = ziglet.CommandContext;
const Atomic = std.atomic.Value;
const Thread = std.Thread;
const std = @import("std");
const terminal = ziglet.utils.terminal;
const Color = terminal.Color;
const printColored = terminal.printColored;
const builtin = @import("builtin");

const InstallationInfo = struct {
    installing: bool,
    version: []const u8,
};

pub fn updateCommand(ctx: CommandContext) !void {
    const allocator = ctx.allocator;
    var checking = Atomic(bool).init(true);

    const installation_info = allocator.create(InstallationInfo) catch unreachable;

    installation_info.* = .{
        .installing = false,
        .version = "",
    };

    var installing = Atomic(*InstallationInfo).init(installation_info);

    const animation_thread = try Thread.spawn(.{}, animate, .{ &checking, &installing });
    const check_thread = try Thread.spawn(.{}, checkUpdate, .{ &checking, allocator, &installing });

    check_thread.join();

    if (installing.load(.acquire).installing) {
        const install_thread = try Thread.spawn(.{}, install, .{ allocator, &installing });
        install_thread.join();
    }

    checking.store(false, .release);
    animation_thread.join();

    defer allocator.destroy(installation_info);
}

fn animate(is_checking: *Atomic(bool), is_installing: *Atomic(*InstallationInfo)) void {
    const frames = [_][]const u8{ "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" };
    var frame_index: usize = 0;

    while (is_checking.load(.acquire) or is_installing.load(.acquire).installing) {
        std.debug.print("\r{s}{s} {s}{s}", .{
            Color.ansiCode(.white),
            frames[frame_index % frames.len],
            if (is_installing.load(.acquire).installing) "Installing update..." else "Checking for updates...",
            Color.ansiCode(.reset),
        });
        std.Thread.sleep(100 * std.time.ns_per_ms);
        frame_index += 1;
    }
}

fn checkUpdate(is_checking: *Atomic(bool), allocator: std.mem.Allocator, is_installing: *Atomic(*InstallationInfo)) void {
    var child_process = std.process.Child.init(&.{ "curl", "-sL", "https://raw.githubusercontent.com/Kingrashy12/zio/main/version" }, allocator);
    child_process.stdout_behavior = .Pipe;

    child_process.spawn() catch |err| {
        printColored(.red, "Unable to spawn child process:{s}\n", .{@errorName(err)});
        return;
    };

    var buffer: [50]u8 = undefined;

    var first_byte_read: usize = 0;

    if (child_process.stdout) |out| {
        const len = out.readAll(&buffer) catch |err| {
            printColored(.red, "Unable to read child process output:{s}\n", .{@errorName(err)});
            return;
        };
        first_byte_read = len;
    }

    _ = child_process.wait() catch {
        printColored(.red, "Unable to wait for child process\n", .{});
        return;
    };

    const version = std.mem.trim(u8, buffer[0..first_byte_read], &std.ascii.whitespace);

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

    const raw = current_buffer[0..byte_read];
    const clean = stripAnsi(allocator, raw) catch unreachable;
    defer allocator.free(clean);

    const current_version = std.mem.trim(u8, clean, &std.ascii.whitespace);

    const is_updated = std.mem.eql(u8, version, current_version);

    if (is_updated) {
        printColored(.magenta, "\r🤗 zio is up to date!    \n", .{});
    } else {
        std.debug.print("\r{s}✨ New update available!   {s}\n", .{
            Color.ansiCode(.yellow),
            Color.ansiCode(.reset),
        });

        is_installing.load(.seq_cst).installing = true;
        is_installing.load(.seq_cst).version = allocator.dupe(u8, version) catch unreachable;
    }

    is_checking.store(false, .release);
}

fn install(allocator: std.mem.Allocator, installing: *Atomic(*InstallationInfo)) void {
    if (!installing.load(.acquire).installing) return;

    const cmd = if (builtin.os.tag == .windows)
        &.{ "cmd", "/c", "curl -sL https://raw.githubusercontent.com/Kingrashy12/zio/main/install.bash | bash" }
    else
        &.{ "sh", "-c", "curl -sL https://raw.githubusercontent.com/Kingrashy12/zio/main/install.bash | sudo bash" };

    var child = std.process.Child.init(cmd, allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    child.spawn() catch |err| {
        printColored(.red, "Unable to spawn child process:{s}\n", .{@errorName(err)});
        return;
    };

    _ = child.wait() catch {
        printColored(.red, "Unable to wait for child process\n", .{});
        return;
    };

    installing.load(.seq_cst).installing = false;

    printColored(.green, "\r✓ Update installed '{s}'\n", .{installing.load(.acquire).version});

    allocator.free(installing.load(.seq_cst).version);
}

fn stripAnsi(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    var i: usize = 0;

    while (i < input.len) {
        if (input[i] == 0x1b and i + 1 < input.len and input[i + 1] == '[') {
            i += 2;
            while (i < input.len and input[i] != 'm') i += 1;
            i += 1;
        } else {
            try out.append(allocator, input[i]);
            i += 1;
        }
    }

    return try out.toOwnedSlice(allocator);
}
