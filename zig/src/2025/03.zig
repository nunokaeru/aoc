const std = @import("std");
const fs = std.fs;

pub fn main() !void {
    var buffer: [2048]u8 = undefined;
    var file = try fs.cwd().openFile("03.input", .{ .mode = .read_only });
    defer file.close();

    var reader: fs.File.Reader = file.reader(&buffer);
    var result: u64 = 0;

    while (try reader.interface.takeDelimiter('\n')) |line| {
        result += parseToJoltage(line);
    }
    std.debug.print("{d}\n", .{result});
}

pub fn digit(ch: u8) ?u8 {
    if (ch >= '0' and ch <= '9') {
        return ch - '0';
    }
    return null;
}

fn parseToJoltage(string: []const u8) u8 {
    var tens: u8 = 0;
    var ones: u8 = 0;
    var tensIndex: usize = 0;
    // Don't test last element
    for (0..string.len - 1) |i| {
        if (digit(string[i])) |n| {
            if (n > tens) {
                tens = n;
                tensIndex = i;
            }
        }
    }
    for (tensIndex + 1..string.len) |i| {
        if (digit(string[i])) |n| {
            if (n > ones) {
                ones = n;
            }
        }
    }
    return 10 * tens + ones;
}

const TestData = struct { string: []const u8, expected: u8 };
test "max" {
    comptime {
        const tests = [_]TestData{
            .{ .string = "11", .expected = 11 },
            .{ .string = "1234", .expected = 34 },
            .{ .string = "2184566849", .expected = 89 },
            .{ .string = "8492", .expected = 92 },
            .{ .string = "81892111", .expected = 92 },
        };
        for (tests) |data| {
            _ = JoltageTest(data);
        }
    }
}

fn JoltageTest(data: TestData) type {
    return struct {
        test {
            try std.testing.expectEqual(
                data.expected,
                parseToJoltage(data.string),
            );
        }
    };
}
