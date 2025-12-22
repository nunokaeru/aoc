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
            if (duplicates(intBuffer[0..], n)) {
                result += n;
            }
        }
    }
    std.debug.print("{d}\n", .{result});
}

fn duplicates(buf: []u8, n: u64) bool {
    const number = std.fmt.bufPrint(buf, "{d}", .{n}) catch return false;
    for (1..number.len) |window_offset| {
        const needle = number[0..window_offset];
        const haystack = number[window_offset..number.len];
        const count = std.mem.count(u8, haystack, needle);
        // std.debug.print("haystack: {s}, needle: {s}, count: {d}\n", .{ needle, haystack, count });
        if (count > 0 and count * window_offset == number.len - window_offset) {
            return true;
        }
    }
    return false;
}

test "duplicated" {
    comptime {
        const values = [_]u64{
            11,
            22,
            1121,
            222,
            1111,
            1212,
            4141,
            192192,
            12121212,
            123123123,
            14561456,
            2121212121,
            824824824,
            1188511885,
        };
        for (values) |n| {
            _ = DuplicatedTest(n);
        }
    }
}

test "not duplicated" {
    comptime {
        const values = [_]u64{
            12,
            13,
            12312,
            41141,
            1992191921992,
        };
        for (values) |n| {
            _ = NotDuplicatedTest(n);
        }
    }
}

fn DuplicatedTest(
    comptime number: u64,
) type {
    return struct {
        test {
            var intBuffer: [20]u8 = undefined;
            try std.testing.expect(duplicates(intBuffer[0..], number));
        }
    };
}

fn NotDuplicatedTest(
    comptime number: u64,
) type {
    return struct {
        test {
            var intBuffer: [20]u8 = undefined;
            try std.testing.expect(!duplicates(intBuffer[0..], number));
        }
    };
}
