//! This is a script to create a large directory structure for testing

const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var cwd = std.fs.cwd();

    // Create root directory
    cwd.makeDir("max_test") catch |err| {
        if (err != std.fs.Dir.MakeError.PathAlreadyExists) {
            return err;
        }
    };

    var max_test_dir = try cwd.openDir("max_test", .{});
    defer max_test_dir.close();

    // Outer loop: 1000 folders
    for (1..1001) |i| {
        const folder_name = try std.fmt.allocPrint(
            allocator,
            "folder_{d}",
            .{i},
        );
        defer allocator.free(folder_name);

        std.debug.print("max_test/{s}\n", .{folder_name});

        // Create folder
        var folder = try max_test_dir.makeOpenPath(folder_name, .{});
        defer folder.close();

        // Inner loop: 10 subfolders per folder
        for (1..11) |j| {
            const sub_name = try std.fmt.allocPrint(
                allocator,
                "sub_{d}",
                .{j},
            );
            defer allocator.free(sub_name);

            std.debug.print("max_test/{s}/{s}\n", .{ folder_name, sub_name });

            // Create subfolder
            try folder.makeDir(sub_name);
        }
    }
}
