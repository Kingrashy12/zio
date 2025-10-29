const ziglet = @import("ziglet");
const ActionArg = ziglet.ActionArg;
const std = @import("std");
const terminal = ziglet.utils.terminal;
const printColored = terminal.printColored;

pub fn removeDirCommand(params: ActionArg) !void {
    const allocator = params.allocator;

    const force = params.options.get("force");

    const args = params.args;

    if (args.len == 0) {
        printColored(.yellow, "Usage: zio rmdir <dir_name>", .{});
    }

    for (args) |name| {
        if (force) |f| {
            const should_force = ziglet.CLIUtils.takeBool(f);

            if (should_force) {
                try forceRemoveDir(name);
            } else {
                try removeDir(name, allocator);
            }
        }
    }
}

fn forceRemoveDir(name: []const u8) !void {
    var cwd = std.fs.cwd();

    cwd.deleteTree(name) catch |err| {
        printColored(.red, "Failed to remove directory '{s}': {s}\n", .{ name, @errorName(err) });
        return;
    };
    printColored(.green, "Removed directory: '{s}'\n", .{name});
}

fn removeDir(name: []const u8, allocator: std.mem.Allocator) !void {
    var cwd = std.fs.cwd();
    cwd.deleteDir(name) catch |err| {
        switch (err) {
            error.FileNotFound => {
                printColored(.red, "Error: Directory '{s}' not found.", .{name});
                return;
            },
            error.DirNotEmpty => {
                const message = try std.fmt.allocPrint(allocator, "Directory '{s}' is not empty. Do you want to force remove it?", .{name});
                defer allocator.free(message);

                const should_force = terminal.confirm(allocator, message) catch {
                    printColored(.red, "Error: Failed to get confirmation input.\n", .{});
                    return;
                };

                if (should_force) {
                    cwd.deleteTree(name) catch |er| {
                        printColored(.red, "Failed to forcibly remove directory '{s}': {s}\n", .{ name, @errorName(er) });
                        return;
                    };
                } else {
                    printColored(.yellow, "Skipped removing directory '{s}'.\n", .{name});
                    return;
                }
            },
            else => {
                printColored(.red, "Failed to remove directory '{s}': {s}\n", .{ name, @errorName(err) });
                return;
            },
        }
    };
    printColored(.green, "Removed directory: '{s}'\n", .{name});
}
