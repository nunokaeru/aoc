const std = @import("std");
const fs = std.fs;

test "print to buffer instaed of on the heap" {
    var buf: [20]u8 = undefined;
    const n: u64 = 11;
    const number = try std.fmt.bufPrint(buf[0..], "{d}", .{n});
    const half = (number.len / 2);
    try std.testing.expect(std.mem.eql(u8, number[0 .. half - 1], number[half .. number.len - 1]));
}
