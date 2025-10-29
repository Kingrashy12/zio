const ziglet = @import("ziglet");
const ActionArg = ziglet.ActionArg;
const std = @import("std");

pub fn deleteCommand(params: ActionArg) !void {
    var cwd = std.fs.cwd();
    const args = params.args;

    if (args.len == 0) {
        ziglet.utils.terminal.printColored(.yellow, "Usage: zio delete <file_name>", .{});
    }

    for (args) |value| {
        cwd.deleteFile(value) catch |err| {
            switch (err) {
                error.FileNotFound => {
                    ziglet.utils.terminal.printColored(.red, "Error: File '{s}' not found.", .{value});
                    return;
                },
                else => {
                    ziglet.utils.terminal.printColored(.red, "Error: Could not delete file '{s}': {s}.", .{ value, @errorName(err) });
                    return;
                },
            }
        };
        ziglet.utils.terminal.printColored(.green, "Deleted file: '{s}'\n", .{value});
    }
}
