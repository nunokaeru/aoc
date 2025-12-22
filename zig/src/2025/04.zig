const std = @import("std");
const fs = std.fs;

pub fn main() !void {
    var buffer: [2048]u8 = undefined;
    var file = try fs.cwd().openFile("04.input", .{ .mode = .read_only });
    defer file.close();

    var reader: fs.File.Reader = file.reader(&buffer);
    const allocator = std.heap.page_allocator;

    const first_line = try reader.interface.peekDelimiterExclusive('\n');
    const columns = first_line.len;
    const stat = try file.stat();
    const rows = stat.size / columns;
    // std.debug.print("columns: {d}, rows: {d}\n", .{ columns, rows });

    var m: Matrix = try .init(allocator, columns, rows);
    defer m.deinit();
    while (try reader.interface.takeDelimiter('\n')) |line| {
        m.list.appendSliceAssumeCapacity(line);
    }
    var grid: std.ArrayList(u8) = try .initCapacity(allocator, columns * rows * 2);
    defer grid.deinit(allocator);

    var result: usize = 0;
    for (0..rows) |row| {
        for (0..columns) |column| {
            const toFill = m.canAccess(column, row);
            if (toFill) {
                try grid.print(allocator, "\x1b[6;30;42m{c}\x1b[0m", .{m.at(column, row).?});
                result += 1;
                continue;
            }
            try grid.print(allocator, "{c}", .{m.at(column, row).?});
        }
        try grid.print(allocator, "\n", .{});
    }
    // std.debug.print("{s}", .{grid.items});
    std.debug.print("{d}\n", .{result});
}

const Matrix = struct {
    columns: usize = undefined,
    rows: usize = undefined,
    allocator: std.mem.Allocator = undefined,
    list: std.ArrayList(u8) = undefined,

    fn init(allocator: std.mem.Allocator, columns: usize, rows: usize) !Self {
        return .{
            .rows = rows,
            .columns = columns,
            .allocator = allocator,
            .list = try .initCapacity(allocator, columns * rows),
        };
    }

    fn deinit(self: *Self) void {
        self.list.deinit(self.allocator);
    }

    const Self = @This();
    fn at(self: Self, column: usize, row: usize) ?u8 {
        if (column >= self.columns) {
            return null;
        }
        if (row >= self.rows) {
            return null;
        }
        const idx = self.columns * row + column;
        std.debug.assert(self.list.items.len > idx);
        return self.list.items[idx];
    }

    fn isFilled(self: Self, column: usize, row: usize) bool {
        const val = self.at(column, row);
        return if (val != '@') false else true;
    }

    fn canAccess(self: Self, column: usize, row: usize) bool {
        var filledPos: u8 = 0;
        if (!self.isFilled(column, row)) {
            return false;
        }
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
            if ((column == 0 and p[0] < 0) or (row == 0 and p[1] < 0)) continue;
            const x = add(column, p[0]);
            const y = add(row, p[1]);

            // std.debug.print("x: {}, y:{}, isFilled:{}\n", .{ x, y, self.isFilled(x, y) });
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
