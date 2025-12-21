const std = @import("std");
const fs = std.fs;

pub fn main() !void {
    var buffer: [2048]u8 = undefined;
    var file = try fs.cwd().openFile("02.input", .{ .mode = .read_only });
    defer file.close();

    var reader: fs.File.Reader = file.reader(&buffer);
    var intBuffer: [20]u8 = undefined;
    var result: u64 = 0;

    while (try reader.interface.takeDelimiter(',')) |line| {
        var numbers = std.mem.splitScalar(u8, line, '-');
        const first = try std.fmt.parseInt(u64, numbers.next() orelse break, 10);
        const second = try std.fmt.parseInt(u64, numbers.next() orelse break, 10);
        for (first..second + 1) |n| { // BUG::> first..second == second does not appear in n
            if (equalHalves(intBuffer[0..], n)) {
                result += n;
            }
        }
    }
    std.debug.print("{d}\n", .{result});
}

fn equalHalves(buf: []u8, n: u64) bool {
    const number = std.fmt.bufPrint(buf, "{d}", .{n}) catch return false;
    const middle = (number.len / 2);
    const first_half = number[0..middle]; // BUG::> 0..0 == nothing, 0..1 == [1]u8
    const last_half = number[middle..number.len];
    // std.debug.print("first: {s}, second: {s}\n", .{ first_half, last_half });
    return std.mem.eql(u8, first_half, last_half);
}

test "equal half" {
    comptime {
        const values = [_]u64{
            11,
            22,
            1111,
            1212,
            4141,
            192192,
        };
        for (values) |n| {
            _ = EqualHalfTest(n);
        }
    }
}

test "not equal half" {
    comptime {
        const values = [_]u64{
            12,
            13,
            111,
            222,
            11211,
            12312,
            41141,
            199219921992,
        };
        for (values) |n| {
            _ = NotEqualHalfTest(n);
        }
    }
}

fn EqualHalfTest(
    comptime number: u64,
) type {
    return struct {
        test {
            var intBuffer: [20]u8 = undefined;
            try std.testing.expect(equalHalves(intBuffer[0..], number));
        }
    };
}

fn NotEqualHalfTest(
    comptime number: u64,
) type {
    return struct {
        test {
            var intBuffer: [20]u8 = undefined;
            try std.testing.expect(!equalHalves(intBuffer[0..], number));
        }
    };
}
