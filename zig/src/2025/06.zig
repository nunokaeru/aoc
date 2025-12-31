const std = @import("std");
const fs = std.fs;

pub fn main() !void {
    var buffer: [4096]u8 = undefined;
    var file = try fs.cwd().openFile("06.input", .{ .mode = .read_only });
    defer file.close();
    var reader: fs.File.Reader = file.reader(&buffer);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    var problem_numbers: std.ArrayList(usize) = try .initCapacity(alloc, 1024);

    const first_line = try reader.interface.takeDelimiter('\n') orelse return;
    var problem_len = std.mem.tokenizeScalar(u8, first_line, ' ');
    var columns: usize = 0;
    while (problem_len.next()) |str| {
        const number = try std.fmt.parseInt(usize, str, 10);
        try problem_numbers.append(alloc, number);
        columns += 1;
    }

    var multiplies: std.ArrayList(bool) = try .initCapacity(alloc, columns);

    while (try reader.interface.takeDelimiter('\n')) |line| {
        const last_line = std.mem.containsAtLeastScalar(u8, line, 1, '*');
        var parts = std.mem.tokenizeScalar(u8, line, ' ');

        if (!last_line) {
            while (parts.next()) |part| {
                const number = try std.fmt.parseInt(usize, part, 10);
                try problem_numbers.append(alloc, number);
            }
        } else {
            while (parts.next()) |part| {
                multiplies.appendAssumeCapacity(std.mem.containsAtLeastScalar(u8, part, 1, '*'));
            }
        }
    }

    var results: std.ArrayList(usize) = try .initCapacity(alloc, columns);
    for (0..columns) |column| {
        var index = column;
        if (multiplies.items[column]) {
            results.appendAssumeCapacity(1);
            while (index < problem_numbers.items.len) {
                results.items[column] *= problem_numbers.items[index];
                index += columns;
            }
        } else {
            results.appendAssumeCapacity(0);
            while (index < problem_numbers.items.len) {
                results.items[column] += problem_numbers.items[index];
                index += columns;
            }
        }
    }
    std.debug.print("Numbers columns: {d}\n", .{columns});
    std.debug.print("ArrayList: {any}\n", .{problem_numbers.items});
    std.debug.print("ArrayList: {any}\n", .{multiplies.items});
    std.debug.print("Results: {any}\n", .{results});
    var result: usize = 0;
    for (results.items) |n| {
        result += n;
    }
    std.debug.print("final: {d}\n", .{result});
}
