const ziglet = @import("ziglet");
const ActionArg = ziglet.ActionArg;
const std = @import("std");
const printColored = ziglet.utils.terminal.printColored;

pub fn renameDirCommand(params: ActionArg) !void {
    var cwd = std.fs.cwd();
    const args = params.args;

    if (args.len == 0) {
        printColored(.yellow, "Usage: zio rndir <old_name>-><new_name>", .{});
    }

    for (args) |value| {
        const parts = std.mem.indexOf(u8, value, "->");

        if (parts == null) {
            printColored(.yellow, "Usage: zio rndir <old_name>-><new_name>", .{});
            return;
        }

        var parts_slice = std.mem.tokenizeAny(u8, value, "->");

        const old_name = parts_slice.next().?;
        const new_name = parts_slice.next().?;

        cwd.rename(old_name, new_name) catch |err| {
            switch (err) {
                error.FileNotFound => {
                    printColored(.red, "Error: Directory '{s}' not found.", .{old_name});
                    return;
                },
                error.PathAlreadyExists => {
                    printColored(.red, "Error: Directory '{s}' already exists.", .{new_name});
                    return;
                },
                else => {
                    printColored(.red, "Error: Could not rename directory '{s}' to '{s}': {s}.", .{ old_name, new_name, @errorName(err) });
                    return;
                },
            }
        };
        printColored(.green, "Renamed directory: '{s}' to '{s}'\n", .{ old_name, new_name });
    }
}
