const std = @import("std");
const fs = std.fs;
const assert = std.debug.assert;

pub fn main() !void {
    var buffer: [2048]u8 = undefined;
    var file = try fs.cwd().openFile("05.input", .{ .mode = .read_only });
    defer file.close();

    var reader: fs.File.Reader = file.reader(&buffer);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

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
        const range: Range = .{ .begin = begin, .end = end };
        try fresh_ranges.append(alloc, range);
    }

    std.mem.sort(Range, fresh_ranges.items, {}, Range.lessThan);
    var result2: usize = 0;
    for (try intersectingRanges(alloc, fresh_ranges.items)) |range| {
        result2 += range.end - range.begin + 1;
    }
    std.debug.print("{d}\n", .{result2});
}

fn intersectingRanges(alloc: std.mem.Allocator, ranges: []Range) ![]Range {
    var result: std.ArrayList(Range) = try .initCapacity(alloc, ranges.len);
    result.appendAssumeCapacity(ranges[0]);
    for (ranges[1..]) |range| {
        const last = &result.items[result.items.len - 1];
        if (range.begin <= last.end) {
            last.end = @max(last.end, range.end);
        } else {
            result.appendAssumeCapacity(range);
        }
    }
    return result.toOwnedSlice(alloc);
}

const Range = struct {
    begin: usize,
    end: usize,

    fn lessThan(_: void, lhs: Range, rhs: Range) bool {
        return lhs.begin < rhs.begin;
    }
};
