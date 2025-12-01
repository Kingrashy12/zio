const ziglet = @import("ziglet");
const CommandContext = ziglet.CommandContext;
const std = @import("std");
const printColored = ziglet.utils.terminal.printColored;

pub fn renameCommand(ctx: CommandContext) !void {
    var cwd = std.fs.cwd();
    const args = ctx.args;

    if (args.len == 0) {
        printColored(.yellow, "Usage: zio rename <old_name>-><new_name>", .{});
    }

    for (args) |value| {
        const parts = std.mem.indexOf(u8, value, "->");

        if (parts == null) {
            printColored(.yellow, "Usage: zio rename <old_name>-><new_name>", .{});
            return;
        }

        var parts_slice = std.mem.tokenizeAny(u8, value, "->");

        const old_name = parts_slice.next().?;
        const new_name = parts_slice.next();

        if (new_name == null) {
            printColored(.yellow, "Missing new name in argument: {s}. Expected format: <old_name>-><new_name>", .{value});
            return;
        }

        cwd.rename(old_name, new_name.?) catch |err| {
            switch (err) {
                error.FileNotFound => {
                    printColored(.red, "Error: File '{s}' not found.", .{old_name});
                    return;
                },
                error.PathAlreadyExists => {
                    printColored(.red, "Error: File '{s}' already exists.", .{new_name.?});
                    return;
                },
                else => {
                    printColored(.red, "Error: Could not rename file '{s}' to '{s}': {s}.", .{ old_name, new_name.?, @errorName(err) });
                    return;
                },
            }
        };
        printColored(.green, "Renamed file: '{s}' to '{s}'\n", .{ old_name, new_name.? });
    }
}
