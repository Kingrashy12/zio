const std = @import("std");
const ziglet = @import("ziglet");
const CLIBuilder = ziglet.CLIBuilder;
const commands = @import("commands/root.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var cli = CLIBuilder.init(allocator, "zio", "0.1.0", "A blazing-fast file system utility designed for efficiency and reliability.");
    defer cli.deinit();

    // ---------------- ------------ [[File Commands]] ---------------- ------------ //

    // ================= Create Command =================
    _ = cli.command("create", "Create new file in the current directory.").action(commands.createCommand).finalize();

    // ================= Delete Command =================
    _ = cli.command("delete", "Delete a file from the current directory.").action(commands.deleteCommand).finalize();

    // ================= List Command =================
    _ = cli.command("list", "List all files in the current directory.").action(commands.listCommand).finalize();

    // ================= Move Command =================
    _ = cli.command("move", "Move a file to a new location.").action(commands.moveCommand).finalize();

    // ================= Rename Command =================
    _ = cli.command("rename", "Rename a file in the current directory.").action(commands.renameCommand).finalize();

    // ---------------------------- [[ Directory Commands ]] ---------------------------- //

    try cli.parse(args, &.{});
}
