const ziglet = @import("ziglet");
const ActionArg = ziglet.ActionArg;
const std = @import("std");
const printColored = ziglet.utils.terminal.printColored;

pub fn moveCommand(params: ActionArg) !void {
    var cwd = std.fs.cwd();

    const args = params.args;

    if (args.len == 0) {
        printColored(.yellow, "Usage: zio move <old_location>-><new_location>", .{});
    }

    for (args) |arg| {
        const parts = std.mem.indexOf(u8, arg, "->");

        if (parts == null) {
            printColored(.red, "Invalid argument format: {s}. Expected format: <old_location>-><new_location>", .{arg});
            return;
        }

        var parts_slice = std.mem.tokenizeAny(u8, arg, "->");

        const old_location = parts_slice.next().?;
        const new_location = parts_slice.next();

        if (new_location == null) {
            printColored(.red, "Missing new location in argument: {s}. Expected format: <old_location>-><new_location>", .{arg});
            return;
        }

        // Since this is a move operation ensure the filename are same, <e.g> users.json -> data/users.json
        const old_name = std.fs.path.basename(old_location);
        const new_name = std.fs.path.basename(new_location.?);

        if (!std.mem.eql(u8, old_name, new_name)) {
            printColored(.red, "Error: Move operation requires the same filename. Example: 'data.txt -> folder/data.txt'. Got '{s}' -> '{s}'", .{ old_name, new_name });
            return;
        }

        cwd.rename(old_location, new_location.?) catch |err| {
            switch (err) {
                error.FileNotFound => {
                    printColored(.red, "Error: Source file '{s}' not found.", .{old_location});
                    return;
                },
                error.PathAlreadyExists => {
                    printColored(.red, "Error: Destination '{s}' already exists.", .{new_location.?});
                    return;
                },
                else => {
                    printColored(.red, "Error: Could not rename file '{s}' to '{s}': {s}.", .{ old_location, new_location.?, @errorName(err) });
                    return;
                },
            }
        };
        printColored(.green, "Moved file: '{s}' to '{s}'\n", .{ old_location, new_location.? });
    }
}
