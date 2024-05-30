const std = @import("std");
const http = std.http;
const ChildProcess = std.ChildProcess;
const Mutex = std.Thread.Mutex;
const Thread = std.Thread;
const State = enum { connected, disconnected };
const Uri = std.Uri;
const RequestOptions = http.Client.RequestOptions;
const Data = struct {
    lock: Mutex = Mutex{},
    state: State,
    const Self = @This();
    pub fn to_connect(self: *Self) void {
        self.lock.lock();
        defer self.lock.unlock();
        self.state = State.connected;
    }
    pub fn to_disconnect(self: *Self) void {
        self.lock.lock();
        defer self.lock.unlock();
        self.state = State.disconnected;
    }
    pub fn print(self: *Self) void {
        std.debug.print("State : {}", .{self.state});
    }
};
pub fn detect_conection_state(state: *Data) void {
    std.time.sleep(1000 * std.time.ns_per_ms);
    state.to_connect();
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    // var buffer = std.ArrayList(u8).init(allocator);
    var data = Data{ .state = State.disconnected };
    const uri = Uri.parse("http://solonumeros.com.ar:2000") catch |e| errloop: {
        std.debug.print("error {}", .{e});
        break :errloop try Uri.parse("");
    };

    var client = http.Client{ .allocator = allocator };
    var shb: [100]u8 = undefined;
    // var arr = std.ArrayList(u8).init(allocator);
    const options = RequestOptions{ .server_header_buffer = &shb };

    // const req = try client.connect(uri.host.?, 2000, http.Client.Connection.Protocol.plain);
    var req = client.open(http.Method.GET, uri, options) catch |err| errloop: {
        std.debug.print("AAAAAAAAAA {any}", .{err});
        break :errloop try client.open(http.Method.GET, try Uri.parse("http://www.google.com"), options);
    };
    std.debug.print("{any}", .{req});

    // defer req
    const body = req.reader().readAllAlloc(allocator, 8192) catch |err| errloop: {
        std.debug.print("Error en lectura de respuesta = {}", .{err});
        break :errloop &.{};
    };

    errdefer std.debug.print("Caught error", .{});
    std.debug.print("{s}", .{body});
    defer client.deinit();
    {
        const fetch_connection = try Thread.spawn(.{}, detect_conection_state, .{&data});
        defer fetch_connection.join();
    }
    data.print();
}
