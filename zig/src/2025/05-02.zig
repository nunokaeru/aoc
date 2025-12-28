const std = @import("std");
const fs = std.fs;
const assert = std.debug.assert;

var treeBuffer: [1024]Tree.Node = undefined;
pub fn main() !void {
    var buffer: [2048]u8 = undefined;
    var file = try fs.cwd().openFile("05.input", .{ .mode = .read_only });
    defer file.close();

    var reader: fs.File.Reader = file.reader(&buffer);
    var tree = Tree{};

    while (try reader.interface.takeDelimiter('\n')) |line| {
        var it = std.mem.splitScalar(u8, line, '-');
        const first = it.next();
        if (first == null or first.?.len == 0) {
            break;
        }
        const begin = try std.fmt.parseInt(usize, first.?, 10);
        const end = try std.fmt.parseInt(usize, it.next().?, 10);
        const range: Range = .{ .begin = begin, .end = end };
        _ = tree.insertRange(range);
    }

    std.debug.print("{d}\n", .{tree.total(Tree.Index.root)});
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
const Tree = struct {
    const Self = @This();
    const Index = enum(u32) {
        root = 0,
        invalid = std.math.maxInt(u32),
        _,
    };
    const Node = struct {
        left: Index,
        right: Index,
        range: Range,

        fn new(range: Range) Node {
            return .{
                .left = .invalid,
                .right = .invalid,
                .range = range,
            };
        }
    };

    nodes: []Node = treeBuffer[0..0],

    fn get(self: Self, index: Index) *Node {
        return &self.nodes[@intFromEnum(index)];
    }

    fn insertRange(self: *Self, range: Range) Index {
        if (self.nodes.len == 0) {
            self.nodes.len = @intFromEnum(Index.root) + 1;

            self.nodes[@intFromEnum(Index.root)] = Node.new(range);
            return .root;
        }
        var index = Index.root;

        while (true) {
            const parent = self.get(index);
            // Range ends before Node's range
            if (range.end < parent.range.begin) {
                if (parent.left == .invalid) {
                    const nodeIndex: Index = @enumFromInt(self.nodes.len);
                    self.nodes.len += 1;
                    parent.left = nodeIndex;
                    self.nodes[@intFromEnum(nodeIndex)] = Node.new(range);
                    return nodeIndex;
                }
                index = parent.left;
                continue;
            }
            // Range starts after node's range
            if (range.begin > parent.range.end) {
                if (parent.right == .invalid) {
                    const nodeIndex: Index = @enumFromInt(self.nodes.len);
                    self.nodes.len += 1;
                    parent.right = nodeIndex;
                    self.nodes[@intFromEnum(nodeIndex)] = Node.new(range);
                    return nodeIndex;
                }
                index = parent.right;
                continue;
            }

            if (range.begin >= parent.range.begin and range.end <= parent.range.end) {
                return index;
            }

            // Range overlaps node's range on the left side
            if (range.end >= parent.range.begin and range.end <= parent.range.end) {
                self.squashLeft(parent, range);
                return index;
            }
            // Range overlaps node's range on the right side
            if (range.begin <= parent.range.end and range.begin >= parent.range.begin) {
                self.squashRight(parent, range);
                return index;
            }
            if (range.begin < parent.range.begin and range.end > parent.range.end) {
                self.squashLeft(parent, range);
                self.squashRight(parent, range);
                return index;
            }
            if (range.begin == parent.range.begin and range.end == parent.range.end) {
                return index;
            }
        }
        return .invalid;
    }

    fn squashRight(self: *Self, parent: *Node, range: Range) void {
        parent.range.end = @max(range.end, parent.range.end);

        var nextIndex = parent.right;
        var childIndex: *Index = &parent.right;
        while (nextIndex != .invalid) {
            const nextNode = self.get(nextIndex);
            if (parent.range.end < nextNode.range.begin) {
                childIndex = &nextNode.left;
                nextIndex = nextNode.left;
                continue;
            }
            parent.range.end = @max(nextNode.range.end, parent.range.end);
            childIndex.* = nextNode.right;
            nextIndex = nextNode.right;
        }
    }

    fn squashLeft(self: *Self, parent: *Node, range: Range) void {
        parent.range.begin = @min(range.begin, parent.range.begin);

        var nextIndex = parent.left;
        var childIndex: *Index = &parent.left;

        while (nextIndex != .invalid) {
            const nextNode = self.get(nextIndex);
            if (parent.range.begin > nextNode.range.end) {
                childIndex = &nextNode.right;
                nextIndex = nextNode.right;
                continue;
            }
            parent.range.begin = @min(nextNode.range.begin, parent.range.begin);
            childIndex.* = nextNode.left;
            nextIndex = nextNode.left;
        }
    }

    fn total(self: Self, index: Index) usize {
        if (index == .invalid) {
            return 0;
        }
        const root = self.get(index);
        const diff = root.range.end - root.range.begin + 1;
        return diff + self.total(root.left) + self.total(root.right);
    }

    pub fn printNode(self: Self, writer: *std.Io.Writer, nodeIndex: Index, indent: usize) !void {
        const root = self.get(nodeIndex);
        try writer.splatByteAll(' ', indent);
        try writer.print(
            "> Node: [{d}-{d}]\n",
            .{ root.range.begin, root.range.end },
        );
        if (root.left != .invalid) {
            try self.printNode(writer, root.left, indent + 2);
        }
        if (root.right != .invalid) {
            try self.printNode(writer, root.right, indent + 2);
        }
    }

    pub fn format(self: Self, writer: *std.Io.Writer) !void {
        if (self.nodes.len == 0) {
            try writer.writeAll("Error 'Tree' is invalid");
        }
        try self.printNode(writer, .root, 0);
    }
};

test "Tree base state" {
    var tree: Tree = Tree{};
    try std.testing.expectEqual(tree.nodes.len, 0);
    const root = tree.insertRange(.{ .begin = 10, .end = 20 });
    try std.testing.expectEqual(.root, root);
    const node = tree.get(.root);

    try std.testing.expectEqual(10, node.range.begin);
    try std.testing.expectEqual(20, node.range.end);

    const nodeViaSetter = tree.get(root);
    try std.testing.expectEqual(10, nodeViaSetter.range.begin);
    try std.testing.expectEqual(20, nodeViaSetter.range.end);
}

test "Tree insert non-overlapping ranges" {
    var tree: Tree = Tree{};
    _ = tree.insertRange(.{ .begin = 10, .end = 20 });
    _ = tree.insertRange(.{ .begin = 5, .end = 7 }); // left
    _ = tree.insertRange(.{ .begin = 8, .end = 9 }); // left.right
    _ = tree.insertRange(.{ .begin = 30, .end = 33 }); // right
    _ = tree.insertRange(.{ .begin = 26, .end = 27 }); // right.left
    _ = tree.insertRange(.{ .begin = 24, .end = 25 }); // right.left
    _ = tree.insertRange(.{ .begin = 100, .end = 120 }); // right.right
    _ = tree.insertRange(.{ .begin = 123, .end = 125 }); // right.right
    _ = tree.insertRange(.{ .begin = 1, .end = 2 });

    var formatBuffer: [1024]u8 = undefined;
    const printedTree = try std.fmt.bufPrint(
        &formatBuffer,
        "{f}",
        .{tree},
    );
    try std.testing.expectEqualStrings(
        \\> Node: [10-20]
        \\  > Node: [5-7]
        \\    > Node: [1-2]
        \\    > Node: [8-9]
        \\  > Node: [30-33]
        \\    > Node: [26-27]
        \\      > Node: [24-25]
        \\    > Node: [100-120]
        \\      > Node: [123-125]
        \\
    , printedTree);
}

test "Tree insert simple overlapping ranges" {
    var tree: Tree = Tree{};
    _ = tree.insertRange(.{ .begin = 10, .end = 20 }); // root
    _ = tree.insertRange(.{ .begin = 5, .end = 7 }); // left
    _ = tree.insertRange(.{ .begin = 30, .end = 33 }); // right
    _ = tree.insertRange(.{ .begin = 15, .end = 22 }); // replace root
    _ = tree.insertRange(.{ .begin = 2, .end = 5 }); // replace left

    var formatBuffer: [1024]u8 = undefined;
    const printedTree = try std.fmt.bufPrint(
        &formatBuffer,
        "{f}",
        .{tree},
    );
    try std.testing.expectEqualStrings(
        \\> Node: [10-22]
        \\  > Node: [2-7]
        \\  > Node: [30-33]
        \\
    , printedTree);
}

test "Zigzag" {
    var tree: Tree = Tree{};
    _ = tree.insertRange(.{ .begin = 50, .end = 55 }); // root
    _ = tree.insertRange(.{ .begin = 100, .end = 100 }); // right
    _ = tree.insertRange(.{ .begin = 75, .end = 80 }); // right.left
    _ = tree.insertRange(.{ .begin = 90, .end = 97 }); // right.left.right
    _ = tree.insertRange(.{ .begin = 105, .end = 110 }); // right.right
    _ = tree.insertRange(.{ .begin = 92, .end = 100 }); // issue

    var formatBuffer: [1024]u8 = undefined;
    const printedTree = try std.fmt.bufPrint(
        &formatBuffer,
        "{f}",
        .{tree},
    );
    try std.testing.expectEqualStrings(
        \\> Node: [50-55]
        \\  > Node: [90-100]
        \\    > Node: [75-80]
        \\    > Node: [105-110]
        \\
    , printedTree);
}

test "Tree insert overlapping ranges with tree re-arrange" {
    var tree: Tree = Tree{};
    _ = tree.insertRange(.{ .begin = 50, .end = 60 }); // root
    _ = tree.insertRange(.{ .begin = 10, .end = 20 }); // left
    _ = tree.insertRange(.{ .begin = 1, .end = 3 }); // left.left
    _ = tree.insertRange(.{ .begin = 30, .end = 40 }); // left.right
    _ = tree.insertRange(.{ .begin = 42, .end = 45 }); // left.right.right
    _ = tree.insertRange(.{ .begin = 11, .end = 31 }); // replace left

    var formatBuffer: [1024]u8 = undefined;
    const printedTree = try std.fmt.bufPrint(
        &formatBuffer,
        "{f}",
        .{tree},
    );
    try std.testing.expectEqualStrings(
        \\> Node: [50-60]
        \\  > Node: [10-40]
        \\    > Node: [1-3]
        \\    > Node: [42-45]
        \\
    , printedTree);
}

test "Tree insert bigger in both sides range" {
    var tree: Tree = Tree{};
    _ = tree.insertRange(.{ .begin = 50, .end = 60 }); // root
    _ = tree.insertRange(.{ .begin = 10, .end = 20 }); // left
    _ = tree.insertRange(.{ .begin = 30, .end = 50 }); // left.right
    _ = tree.insertRange(.{ .begin = 3, .end = 4 }); // left.left
    _ = tree.insertRange(.{ .begin = 70, .end = 80 }); // right
    _ = tree.insertRange(.{ .begin = 90, .end = 120 }); // right.right
    _ = tree.insertRange(.{ .begin = 7, .end = 101 }); // right

    var formatBuffer: [1024]u8 = undefined;
    const printedTree = try std.fmt.bufPrint(
        &formatBuffer,
        "{f}",
        .{tree},
    );
    try std.testing.expectEqualStrings(
        \\> Node: [7-120]
        \\  > Node: [3-4]
        \\
    , printedTree);
}

test "mutate array item" {
    const Point = struct { x: usize, y: usize };
    const Arr = struct {
        array: [1]Point = undefined,
    };

    var arr: Arr = .{};
    arr.array[0] = .{ .x = 0, .y = 0 };
    const access = &arr.array[0];
    access.x = @intCast(2);
    try std.testing.expectEqual(2, arr.array[0].x);
}
