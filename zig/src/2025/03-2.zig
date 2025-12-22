const std = @import("std");
const fs = std.fs;
const assert = std.debug.assert;

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

fn parseToJoltage(string: []const u8) u64 {
    var joltage: [12]u8 = @splat('0');
    var startIndex: usize = 0;
    for (0..joltage.len) |i| {
        // For a 12 string character there's 11 invalid positions for the
        // first character, therefore the +1
        for (startIndex..string.len - joltage.len + i + 1) |j| {
            if (string[j] > joltage[i]) {
                joltage[i] = string[j];
                // Make sure to resume from the position after the current match
                startIndex = j + 1;
            }
        }
    }
    return std.fmt.parseInt(u64, joltage[0..], 10) catch return 0;
}

const TestData = struct { string: []const u8, expected: u64 };
test "max" {
    comptime {
        const tests = [_]TestData{
            .{ .string = "543211111111111", .expected = 543211111111 },
            .{ .string = "112121111111111111", .expected = 221_111_111_111 },
            .{ .string = "112121111111111", .expected = 221_111_111_111 },
            .{ .string = "11212111111111", .expected = 212_111_111_111 },
            .{ .string = "1121211111111", .expected = 121_211_111_111 },
            .{ .string = "121211111111", .expected = 121_211_111_111 },
            .{ .string = "1234123412341234", .expected = 423412341234 },
            .{ .string = "12184566849121", .expected = 284566849121 },
            .{ .string = "8125111998889999", .expected = 851998889999 },
            .{ .string = "987654321111111", .expected = 987654321111 },
            .{ .string = "811111111111119", .expected = 811111111119 },
            .{ .string = "234234234234278", .expected = 434234234278 },
            .{ .string = "811311111111119", .expected = 831_111_111_119 },
            .{ .string = "811111111131119", .expected = 811_111_131_119 },
            .{ .string = "818181911111211", .expected = 888_911_111_211 },
            //
            .{ .string = "987654321111111", .expected = 987654321111 },
            .{ .string = "818181911112111", .expected = 888911112111 },
            .{ .string = "4641144244413454444424423342544444342452422334233433444444444433441244134444334334433442445541322435", .expected = 655_555_432_435 },
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
