const std = @import("std");
const ziglet = @import("ziglet");
const CLIUtils = ziglet.CLIUtils;
const CommandContext = ziglet.CommandContext;
const terminal = ziglet.utils.terminal;
const print = terminal.print;
const printColored = terminal.printColored;

pub fn shouldIgnore(path: []const u8, patterns: [][]u8) bool {
    for (patterns) |p| {
        // Exact file match
        if (std.mem.eql(u8, path, p)) return true;

        // Prefix directory ignore
        if (std.mem.startsWith(u8, path, p)) return true;

        // Simple wildcard suffix matching
        if (std.mem.startsWith(u8, p, "*")) {
            const suffix = p[1..];
            if (std.mem.endsWith(u8, path, suffix)) return true;
        }
    }
    return false;
}

pub fn statsCommand(ctx: CommandContext) !void {
    const allocator = ctx.allocator;
    const args = ctx.args; // This would be list of dir to ignore

    var dir = try std.fs.cwd().openDir("", .{ .iterate = true });
    defer dir.close();

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    var files: std.ArrayList([]const u8) = .empty;
    defer {
        for (files.items) |value| {
            allocator.free(value);
        }
        files.deinit(allocator);
    }

    try walkFiles(allocator, &dir, "", &files, args);

    for (files.items) |file| {
        print("File: {s}\n", .{file});
    }
}

pub fn walkFiles(
    allocator: std.mem.Allocator,
    dir: *std.fs.Dir,
    base_path: []const u8,
    files: *std.ArrayList([]const u8),
    ignore_paths: [][]u8,
) !void {
    var it = dir.iterate();

    while (try it.next()) |entry| {
        const name = entry.name;

        const full_path = try std.fs.path.join(allocator, &.{ base_path, name });

        // Check ignore
        if (shouldIgnore(full_path, ignore_paths)) {
            allocator.free(full_path); // Free ignored memory
            continue;
        }

        switch (entry.kind) {
            .file => {
                try files.append(allocator, full_path);
                // Caller frees later
            },
            .directory => {
                var sub_dir = dir.openDir(name, .{ .iterate = true }) catch {
                    allocator.free(full_path);
                    continue;
                };
                defer sub_dir.close();

                // Recurse
                walkFiles(allocator, &sub_dir, full_path, files, ignore_paths) catch {
                    allocator.free(full_path);
                    return;
                };

                allocator.free(full_path); // Always free after recursion
            },
            else => {
                allocator.free(full_path); // Avoid forgetting weird entries
            },
        }
    }
}
