const ziglet = @import("ziglet");
const ActionArg = ziglet.ActionArg;
const std = @import("std");
const printColored = ziglet.utils.terminal.printColored;

pub fn createCommand(params: ActionArg) !void {
    var cwd = std.fs.cwd();

    const args = params.args;

    if (args.len == 0) {
        printColored(.yellow, "Usage: zio create <file_name>", .{});
    }

    for (args) |name| {
        var new_file = cwd.createFile(name, .{}) catch |err| {
            switch (err) {
                error.PathAlreadyExists => {
                    printColored(.red, "Error: File '{s}' already exists.", .{name});
                    return;
                },
                else => return err,
            }
        };
        defer new_file.close();
        printColored(.green, "Created file: '{s}'\n", .{name});
    }
}
