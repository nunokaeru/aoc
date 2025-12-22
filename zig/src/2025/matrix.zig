const std = @import("std");
const fs = std.fs;

test "make a matrix" {
    const repr = "@@@\n...\n@@@";
    const allocator = std.testing.allocator;
    const rows = std.mem.indexOfScalar(u8, repr, '\n') orelse repr.len;
    const columns = repr.len / rows;

    var m: Matrix = try .init(allocator, rows, columns);
    defer m.deinit();

    var iterator = std.mem.splitScalar(u8, repr, '\n');
    while (iterator.next()) |line| {
        m.list.appendSliceAssumeCapacity(line);
    }
    try std.testing.expectEqual(repr.len - 2, m.list.items.len);
    try std.testing.expectEqualSlices(u8, "@@@...@@@"[0..], m.list.items);
    try std.testing.expectEqual('@', m.at(0, 0));
    try std.testing.expectEqual('.', m.at(0, 1));
    try std.testing.expect(m.isFilled(0, 0));
    try std.testing.expect(!m.isFilled(0, 1));
    try std.testing.expect(!m.isFilled(0, 123));
    try std.testing.expect(!m.isFilled(213, 1));
    try std.testing.expect(!m.canFill(1, 1));
    try std.testing.expect(!m.canFill(2, 1));
    try std.testing.expect(m.canFill(0, 0));
    try std.testing.expect(m.canFill(0, 1));
    try std.testing.expect(m.canFill(2, 2));
    try std.testing.expect(m.canFill(1, 2));
}

const Matrix = struct {
    rows: usize = undefined,
    columns: usize = undefined,
    allocator: std.mem.Allocator = undefined,
    list: std.ArrayList(u8) = undefined,

    fn init(allocator: std.mem.Allocator, rows: usize, columns: usize) !Self {
        return .{
            .columns = columns,
            .rows = rows,
            .allocator = allocator,
            .list = try .initCapacity(allocator, rows * columns),
        };
    }

    fn deinit(self: *Self) void {
        self.list.deinit(self.allocator);
    }

    const Self = @This();
    fn at(self: Self, row: usize, column: usize) ?u8 {
        if (row >= self.rows) {
            return null;
        }
        if (column >= self.columns) {
            return null;
        }
        const idx = row + column * self.rows;
        std.debug.assert(self.list.items.len > idx);
        return self.list.items[idx];
    }

    fn isFilled(self: Self, row: usize, column: usize) bool {
        const val = self.at(row, column);
        return if (val != '@') false else true;
    }

    fn canFill(self: Self, row: usize, column: usize) bool {
        var filledPos: u8 = 0;
        const Coordinates = struct { i8, i8 };
        const pos: [8]Coordinates = .{
            .{ -1, -1 },
            .{ -1, 0 },
            .{ -1, 1 },
            .{ 0, -1 },
            .{ 0, 1 },
            .{ 1, -1 },
            .{ 1, 0 },
            .{ 1, 1 },
        };
        for (pos) |p| {
            if (row == 0 or column == 0) continue;
            const x = add(row, p[0]);
            const y = add(column, p[1]);
            // std.debug.print("x: {}, y:{}, filledPos:{}\n", .{ x, y, filledPos });
            filledPos += if (self.isFilled(x, y)) 1 else 0;
            // std.debug.print("after: {}\n", .{filledPos});
        }
        return filledPos < 4;
    }
};

fn add(x: usize, y: i8) usize {
    const castedX: i64 = @intCast(x);
    return @intCast(castedX + y);
}
