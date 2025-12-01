const ziglet = @import("ziglet");
const CommandContext = ziglet.CommandContext;
const std = @import("std");
const printColored = ziglet.utils.terminal.printColored;

pub fn mkdirCommand(ctx: CommandContext) !void {
    var cwd = std.fs.cwd();

    const args = ctx.args;

    if (args.len == 0) {
        printColored(.yellow, "Usage: zio mkdir <dir_name>", .{});
    }

    for (args) |name| {
        cwd.makeDir(name) catch |err| {
            switch (err) {
                error.PathAlreadyExists => {
                    printColored(.red, "Error: Directory '{s}' already exists.", .{name});
                    return;
                },
                else => {
                    printColored(.red, "Failed to create directory '{s}': {s}\n", .{ name, @errorName(err) });
                    return;
                },
            }
        };

        printColored(.green, "Created directory: '{s}'\n", .{name});
    }
}
