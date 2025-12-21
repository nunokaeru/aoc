const std = @import("std");
const fs = std.fs;

pub fn main() !void {
    var buffer: [2048]u8 = undefined;
    var file = try fs.cwd().openFile("01.input", .{ .mode = .read_only });
    defer file.close();

    var reader: fs.File.Reader = file.reader(&buffer);
    const stream = &reader.interface;

    var dial: isize = 50;
    var i: usize = 0;
    while (stream.takeDelimiterExclusive('\n')) |line| {
        _ = stream.toss(1);
        var n: isize = 0;
        // try std.fmt.parseInt(u16, line[1..line.len], 10);
        for (1..line.len) |pos| {
            n = 10 * n + (line[pos] - '0');
        }
        if (line[0] == 'L') {
            dial = @mod((dial - n), 100);
        }
        if (line[0] == 'R') {
            dial = @rem((dial + n), 100);
        }
        if (dial == 0) i += 1;
    } else |_| {}
    std.debug.print("{d}\n", .{i});
}
