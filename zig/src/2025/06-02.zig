const std = @import("std");
const fs = std.fs;

pub fn main() !void {
    var buffer: [4096]u8 = undefined;
    var file = try fs.cwd().openFile("06.input", .{ .mode = .read_only });
    defer file.close();
    var reader: fs.File.Reader = file.reader(&buffer);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    const first_line = try reader.interface.peekDelimiterExclusive('\n');
    const columns = first_line.len;
    var problem_numbers: std.ArrayList(usize) = try .initCapacity(alloc, columns);

    while (try reader.interface.takeDelimiter('\n')) |line| {
        for (line, 0..) |char, index| {
            switch (char) {
                ' ' => {
                    if (index >= problem_numbers.items.len) {
                        try problem_numbers.append(alloc, 0);
                    }
                },
                '0'...'9' => {
                    const n = char - '0';
                    if (index >= problem_numbers.items.len) {
                        try problem_numbers.append(alloc, n);
                    } else {
                        problem_numbers.items[index] = 10 * problem_numbers.items[index] + n;
                    }
                },
                else => {},
            }
        }
        // Leave during the last line
        const first_character = try reader.interface.peek(1);
        if (first_character[0] == '*' or first_character[0] == '+') {
            break;
        }
    }

    var result: usize = 0;
    while (try reader.interface.takeDelimiter('\n')) |line| {
        for (line, 0..) |char, index| {
            const next = std.mem.indexOfAnyPos(u8, line, index + 1, "+*") orelse line.len + 1;
            if (char == '+') {
                var add: usize = 0;
                for (index..next - 1) |i| {
                    // std.debug.print("++ index: {d}, next: {d}, problem_id: {d}\n", .{ index, next, problem_numbers.items[i] });
                    add += problem_numbers.items[i];
                }
                result += add;
                // std.debug.print("++ {d}\n", .{add});
            }
            if (char == '*') {
                var multiply: usize = 1;
                for (index..next - 1) |i| {
                    // std.debug.print("** index: {d}, next: {d}, problem_id: {d}\n", .{ index, next, problem_numbers.items[i] });
                    multiply = multiply * problem_numbers.items[i];
                }
                result += multiply;
                // std.debug.print("** {d}\n", .{multiply});
            }
        }
    }

    // std.debug.print("ArrayList: {any}\n", .{problem_numbers.items});
    // std.debug.print("ArrayList: {any}\n", .{multiplies.items});
    // std.debug.print("Results: {any}\n", .{results});
    std.debug.print("{d}\n", .{result});
}
