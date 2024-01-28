const std = @import("std");
const builtin = @import("builtin");
const phantom = @import("phantom");

const alloc = if (builtin.link_libc) std.heap.c_allocator else std.heap.page_allocator;

pub fn main() !void {
    var platform = try phantom.platform.Backend(.web).Backend.create(alloc);
    defer platform.deinit();
}
