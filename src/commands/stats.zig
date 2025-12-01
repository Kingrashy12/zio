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
    const args = ctx.args; // This would be list of dir or file to ignore

    var dir = try std.fs.cwd().openDir("", .{ .iterate = true });
    defer dir.close();

    var files: std.ArrayList([]const u8) = .empty;
    defer {
        for (files.items) |value| {
            allocator.free(value);
        }
        files.deinit(allocator);
    }

    try walkFiles(allocator, &dir, "", &files, args);

    var total_files: usize = 0;
    var total_lines: usize = 0;

    for (files.items) |path| {
        var file = std.fs.cwd().openFile(path, .{}) catch continue;
        defer file.close();

        const file_size = try file.getEndPos();

        const buffer = try allocator.alloc(u8, @intCast(file_size));
        defer allocator.free(buffer);

        var buf_reader = file.reader(buffer);

        var line_count: usize = 0;

        while (try buf_reader.interface.takeDelimiter('\n')) |_| {
            line_count += 1;
        }

        total_files += 1;
        total_lines += line_count;

        // Print per-file stats
        print("{s}: {d} lines\n", .{ path, line_count });
    }

    print("\nTotal files: {d}\n", .{total_files});
    print("Total lines: {d}\n", .{total_lines});
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
