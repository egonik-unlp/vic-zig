const std = @import("std");
const e = error{ MuyBoludoError, ReBoludoError };

pub fn main() void {
    const q = erroreame(false) catch |err| errloop: {
        std.debug.print("error en ej {any}", .{err});
        break :errloop 22;
    };
    errdefer std.debug.print("AAAAAAAAAAAAAAAAAAAaa", .{});
    std.debug.print("FIN {any}\n", .{q});
    const b = zetso: {
        break :zetso 12;
    };
    std.debug.print("b => {}", .{b});
}

fn erroreame(a: bool) !u32 {
    return if (a) 12 else e.MuyBoludoError;
}
