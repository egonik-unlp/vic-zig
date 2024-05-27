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
    const uri = try Uri.parse("http://solonumeros.com.ar");
    var client = http.Client{ .allocator = allocator };
    var shb: [1024 * 1024]u8 = undefined;
    var buffer: [1024 * 1024]u8 = undefined;
    const options = RequestOptions{ .server_header_buffer = &shb };

    // const req = try client.connect(uri.host.?, 2000, http.Client.Connection.Protocol.plain);
    var req = try client.open(http.Method.GET, uri, options);
    defer req.deinit();
    const bytes_read = try req.reader().read(&buffer);
    std.debug.print("bytes read : {d}", .{bytes_read});
    defer client.deinit();
    {
        const fetch_connection = try Thread.spawn(.{}, detect_conection_state, .{&data});
        defer fetch_connection.join();
    }
    data.print();
}
