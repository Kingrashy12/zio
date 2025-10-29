const ziglet = @import("ziglet");
const ActionArg = ziglet.ActionArg;
const std = @import("std");

pub fn renameCommand(params: ActionArg) !void {
    var cwd = std.fs.cwd();
    const args = params.args;

    if (args.len == 0) {
        ziglet.utils.terminal.printColored(.yellow, "Usage: zio delete <file_name>", .{});
    }

    for (args) |value| {
        const parts = std.mem.indexOf(u8, value, "->");

        if (parts == null) {
            ziglet.utils.terminal.printColored(.yellow, "Usage: zio rename <old_name>-><new_name>", .{});
            return;
        }

        var parts_slice = std.mem.tokenizeAny(u8, value, "->");

        const old_name = parts_slice.next().?;
        const new_name = parts_slice.next().?;

        cwd.rename(old_name, new_name) catch |err| {
            switch (err) {
                error.FileNotFound => {
                    ziglet.utils.terminal.printColored(.red, "Error: File '{s}' not found.", .{old_name});
                    return;
                },
                error.PathAlreadyExists => {
                    ziglet.utils.terminal.printColored(.red, "Error: File '{s}' already exists.", .{new_name});
                    return;
                },
                else => {
                    ziglet.utils.terminal.printColored(.red, "Error: Could not rename file '{s}' to '{s}': {s}.", .{ old_name, new_name, @errorName(err) });
                    return;
                },
            }
        };
        ziglet.utils.terminal.printColored(.green, "Renamed file: '{s}' to '{s}'\n", .{ old_name, new_name });
    }
}
