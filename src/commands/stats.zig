const std = @import("std");
const ziglet = @import("ziglet");
const CLIUtils = ziglet.CLIUtils;
const CommandContext = ziglet.CommandContext;
const terminal = ziglet.utils.terminal;
const print = terminal.print;
const printColored = terminal.printColored;

const FileStats = struct {
    name: []const u8,
    lines: usize,
};

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

const FILE_COL_WIDTH: usize = 65;
const LINES_COL_WIDTH: usize = 12;

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

    var file_stats: std.ArrayList(FileStats) = .empty;
    defer file_stats.deinit(allocator);

    const CHUNK_SIZE: usize = 8192;

    for (files.items) |path| {
        var file = std.fs.cwd().openFile(path, .{}) catch continue;
        defer file.close();

        const file_size = try file.getEndPos();

        var buffer: [CHUNK_SIZE]u8 = undefined;

        var line_count: usize = 0;

        while (file.read(buffer[0..])) |bytes_read| {
            // file.read returns the number of bytes read (0 if EOF)
            if (bytes_read == 0) break;

            // CRITICAL: Count newlines only on the portion of the buffer that was read
            line_count += std.mem.count(u8, buffer[0..bytes_read], "\n");
        } else |err| {
            // Handle I/O errors other than EOF
            if (err != error.EndOfStream) return err;
        }

        if (file_size > 0) {
            // Seek to the end-1 to check the last byte
            try file.seekTo(file_size - 1);
            var last_byte_storage: [1]u8 = undefined;

            const bytes_read = try file.read(last_byte_storage[0..]);
            if (bytes_read == 1 and last_byte_storage[0] != '\n') {
                line_count += 1;
            }
        }

        try file_stats.append(allocator, .{ .name = path, .lines = line_count });
    }

    // Print header
    printColored(.gray, "{s}", .{"File"});
    for ("File".len..FILE_COL_WIDTH) |_| printColored(.gray, " ", .{});
    printColored(.gray, " | ", .{});
    printColored(.gray, "{s}\n", .{"Lines"});

    // Print separator
    for (0..FILE_COL_WIDTH + 3 + LINES_COL_WIDTH) |_| printColored(.gray, "-", .{});
    printColored(.gray, "\n", .{});

    // Print each row
    var total_lines: usize = 0;
    for (file_stats.items) |fs| {
        var file_display = truncateName(fs.name);

        // Add "..." if truncated
        if (fs.name.len > FILE_COL_WIDTH) {
            // allocate temp buffer for truncated + "..."
            var tmp: [FILE_COL_WIDTH]u8 = undefined;
            @memcpy(tmp[0 .. FILE_COL_WIDTH - 3], file_display);
            tmp[FILE_COL_WIDTH - 3] = '.';
            tmp[FILE_COL_WIDTH - 2] = '.';
            tmp[FILE_COL_WIDTH - 1] = '.';
            file_display = tmp[0..FILE_COL_WIDTH];
        }

        // File column
        printColored(.cyan, "{s}", .{file_display});
        for (file_display.len..FILE_COL_WIDTH) |_| printColored(.cyan, " ", .{});

        printColored(.green, " | ", .{});

        const formatted_line_str = try formatNumber(allocator, fs.lines);
        defer allocator.free(formatted_line_str);

        // Right-align lines
        for (formatted_line_str.len..LINES_COL_WIDTH) |_| printColored(.green, " ", .{});
        printColored(.green, "{s}\n", .{formatted_line_str});

        total_lines += fs.lines;
    }

    // Print footer
    for (0..FILE_COL_WIDTH + 3 + LINES_COL_WIDTH) |_| printColored(.gray, "-", .{});
    printColored(.gray, "\n", .{});

    const total_lines_str = try formatNumber(allocator, total_lines);
    defer allocator.free(total_lines_str);

    const total_files_str = try formatNumber(allocator, file_stats.items.len);
    defer allocator.free(total_files_str);

    printColored(.white, "Total files: {s}\n", .{total_files_str});
    printColored(.white, "Total lines: {s}\n", .{total_lines_str});
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

fn repeatChar(allocator: std.mem.Allocator, c: u8, count: usize) ![]u8 {
    const buf = try allocator.alloc(u8, count);
    for (buf) |*b| b.* = c;
    return buf;
}

fn padFixed(s: []const u8, width: usize) []const u8 {
    if (s.len >= width) return s[0..width]; // truncate if too long
    return s;
}

// Helper: truncate filenames if too long
fn truncateName(name: []const u8) []const u8 {
    if (name.len > FILE_COL_WIDTH) return name[0 .. FILE_COL_WIDTH - 3];
    return name;
}

pub fn formatNumber(allocator: std.mem.Allocator, n: usize) ![]const u8 {
    if (n >= 1_000_000_000) {
        const value = n / 1_000_000_000;
        const rem = (n % 1_000_000_000) / 100_000_000; // get 1 decimal
        return try std.fmt.allocPrint(allocator, "{d}.{d}B", .{ value, rem });
    } else if (n >= 1_000_000) {
        const value = n / 1_000_000;
        const rem = (n % 1_000_000) / 100_000; // 1 decimal
        return try std.fmt.allocPrint(allocator, "{d}.{d}M", .{ value, rem });
    } else if (n >= 1_000) {
        const value = n / 1_000;
        const rem = (n % 1_000) / 100; // 1 decimal
        return try std.fmt.allocPrint(allocator, "{d}.{d}K", .{ value, rem });
    } else {
        return try std.fmt.allocPrint(allocator, "{}", .{n});
    }
}
