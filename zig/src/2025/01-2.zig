const std = @import("std");
const fs = std.fs;

pub fn main() !void {
    var buffer: [2048]u8 = undefined;
    var file = try fs.cwd().openFile("01.input", .{ .mode = .read_only });
    defer file.close();

    var reader: fs.File.Reader = file.reader(&buffer);
    const stream = &reader.interface;

    var dial: i32 = 50;
    var i: i32 = 0;
    while (stream.takeDelimiterExclusive('\n')) |line| {
        _ = stream.toss(1);
        var n: i32 = 0;
        // try std.fmt.parseInt(u16, line[1..line.len], 10);
        for (1..line.len) |pos| {
            n = 10 * n + (line[pos] - '0');
        }
        if (line[0] == 'L') {
            i += sub(dial, n);
            dial = @mod((dial - n), 100);
        }
        if (line[0] == 'R') {
            i += @divFloor((dial + n), 100);
            dial = @rem((dial + n), 100);
        }
    } else |_| {}
    std.debug.print("{d}\n", .{i});
}

const expect = std.testing.expect;
test "adding" {
    const vec = [_][3]u32{
        [3]u32{ 98, 3, 1 },
        [3]u32{ 0, 3, 0 },
        [3]u32{ 0, 99, 0 },
        [3]u32{ 0, 100, 1 },
        [3]u32{ 0, 101, 1 },
        [3]u32{ 1, 399, 4 },
        [3]u32{ 99, 330, 4 },
    };
    for (0..vec.len) |i| {
        const dial = vec[i][0];
        const n = vec[i][1];
        const exp = vec[i][2];
        try expect(exp == @abs(@divFloor((dial + n), 100)));
    }
}

test "subtracting" {
    comptime {
        const vec = [_][3]i32{
            [3]i32{ 98, 3, 0 },
            [3]i32{ 4, 3, 0 },
            [3]i32{ 99, 98, 0 },
            [3]i32{ 1, 1, 1 },
            [3]i32{ 1, 102, 2 },
            [3]i32{ 0, 101, 1 },
            [3]i32{ 1, 2, 1 },
            [3]i32{ 1, 399, 4 },
            [3]i32{ 99, 330, 3 },
            [3]i32{ 12, 912, 10 },
            [3]i32{ 95, 765, 7 },
            [3]i32{ 95, 796, 8 },
        };
        for (0..vec.len) |i| {
            const dial = vec[i][0];
            const n = vec[i][1];
            const exp = vec[i][2];
            _ = AddSubTestCase(dial, n, exp);
        }
    }
}

fn AddSubTestCase(
    comptime dial: i32,
    comptime n: i32,
    comptime expected: i32,
) type {
    return struct {
        test {
            std.testing.expectEqual(expected, sub(dial, n)) catch |err| {
                std.debug.print("{}\n", .{@This()});
                return err;
            };
            std.testing.expectEqual(expected, sub2(dial, n)) catch |err| {
                std.debug.print("{}\n", .{@This()});
                return err;
            };
        }
    };
}

fn sub2(dialy: i32, n: i32) i32 {
    var result: i32 = 0;
    var change = -1 * n;
    var dial = dialy;
    while (change != 0) : (change += 1) {
        dial += -1;
        dial = @mod(dial, 100);
        if (dial == 0) result += 1;
    }
    return result;
}

fn sub(dial: i32, n: i32) i32 {
    const turns: i32 = @divFloor(n, 100);
    if (dial == 0) {
        return turns;
    }
    return if (dial - (n - turns * 100) > 0) turns else turns + 1;
}
