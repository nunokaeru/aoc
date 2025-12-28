const std = @import("std");
const fs = std.fs;
const assert = std.debug.assert;

pub fn main() !void {
    var buffer: [2048]u8 = undefined;
    var file = try fs.cwd().openFile("05.input", .{ .mode = .read_only });
    defer file.close();

    var reader: fs.File.Reader = file.reader(&buffer);
    var result: usize = 0;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    const Range = struct { begin: usize, end: usize };
    const stat = try file.stat();
    var fresh_ranges: std.ArrayList(Range) = try .initCapacity(alloc, stat.size / 2);
    defer fresh_ranges.deinit(alloc);

    while (try reader.interface.takeDelimiter('\n')) |line| {
        var it = std.mem.splitScalar(u8, line, '-');
        const first = it.next();
        if (first == null or first.?.len == 0) {
            break;
        }
        const begin = try std.fmt.parseInt(usize, first.?, 10);
        const end = try std.fmt.parseInt(usize, it.next().?, 10);
        try fresh_ranges.append(alloc, .{ .begin = begin, .end = end });
    }
    while (try reader.interface.takeDelimiter('\n')) |line| {
        const id = try std.fmt.parseInt(usize, line, 10);
        for (fresh_ranges.items) |range| {
            if (id >= range.begin and id <= range.end) {
                result += 1;
                break;
            }
        }
    }

    std.debug.print("{d}\n", .{result});
}

test "alloc" {
    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer gpa.deinit();
    const alloc = gpa.allocator();
    var fresh_map = std.AutoArrayHashMapUnmanaged(usize, void){};
    defer fresh_map.deinit(alloc);
    try fresh_map.put(alloc, 1, {});
    try std.testing.expect(fresh_map.contains(1));
}
