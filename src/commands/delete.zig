const ziglet = @import("ziglet");
const CommandContext = ziglet.CommandContext;
const std = @import("std");
const printColored = ziglet.utils.terminal.printColored;

pub fn deleteCommand(ctx: CommandContext) !void {
    var cwd = std.fs.cwd();
    const args = ctx.args;

    if (args.len == 0) {
        printColored(.yellow, "Usage: zio delete <file_name>", .{});
    }

    for (args) |value| {
        cwd.deleteFile(value) catch |err| {
            switch (err) {
                error.FileNotFound => {
                    printColored(.red, "Error: File '{s}' not found.", .{value});
                    return;
                },
                else => {
                    printColored(.red, "Error: Could not delete file '{s}': {s}.", .{ value, @errorName(err) });
                    return;
                },
            }
        };
        printColored(.green, "Deleted file: '{s}'\n", .{value});
    }
}
