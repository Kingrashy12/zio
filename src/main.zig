const std = @import("std");
const ziglet = @import("ziglet");
const CLIBuilder = ziglet.CLIBuilder;
const commands = @import("commands/root.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();

    ziglet.utils.terminal.setWinConsole();

    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var cli = CLIBuilder.init(allocator, "zio", "0.1.9", "A blazing-fast, cross-platform file system utility built in Zig — designed for efficiency, reliability, and simplicity.");
    defer cli.deinit();

    cli.setGlobalOptions();

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

    // ================= Stats Command =================
    _ = cli.command("stats", "Get stats of all files in the current directory.").action(commands.statsCommand).finalize();

    // ---------------------------- [[ Directory Commands ]] ---------------------------- //

    // ================= Make Directory Command =================
    _ = cli.command("mkdir", "Create a new directory in the current location.").action(commands.makeDirCommand).finalize();

    // ================= Remove Directory Command =================
    const rm_dir = cli.command("rmdir", "Remove a directory from the current location.").option(.{
        .name = "force",
        .alias = "f",
        .description = "Force removal of non-empty directory.",
        .type = .bool,
        .default = .{ .bool = false },
    }).action(commands.removeDirCommand).finalize();

    // ================= Rename Directory Command =================
    _ = cli.command("rndir", "Rename a directory in the current location.").action(commands.renameDirCommand).finalize();

    try cli.parse(args, &.{rm_dir});
}
