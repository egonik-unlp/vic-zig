const std = @import("std");
const http = std.http;
const heap = std.heap;
const url = "https://jsonplaceholder.typicode.com/todos/1";
const Client = std.http.Client;
const Headers = std.http.Headers;
const Uri = std.Uri;
const RequestOptions = std.http.Client.RequestOptions;

var gpa_impl = heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

const Req = struct {
    const Self = @This();
    const Allocator = std.mem.Allocator;

    const ReqOptions = struct {
        /// Required
        max: usize,
    };

    allocator: Allocator,
    client: std.http.Client,
    req_options: ReqOptions,

    pub fn init(allocator: Allocator, req_options: ReqOptions) Self {
        const c = Client{ .allocator = allocator };
        return Self{
            .allocator = allocator,
            .client = c,
            .req_options = req_options,
        };
    }

    pub fn deinit(self: *Self) void {
        self.client.deinit();
    }
    const url = url;
    /// Blocking
    pub fn get(self: *Self, url: []const u8, headers: Headers, options: RequestOptions) ![]u8 {
        const uri = try Uri.parse(url);

        var req = try self.client.open(http.Method.GET, uri, headers, options);
        defer req.deinit();

        try req.send(.{});
        try req.wait();

        const res = try req.reader().readAllAlloc(self.allocator, self.req_options.max);
        return res;
    }
};

pub fn main() !void {
    var req = Req.init(gpa, .{ .max = 1024 });
    defer req.deinit();

    var headers = Headers.init(gpa);
    defer headers.deinit();

    const buf = try req.get(url, headers, .{});
    defer req.allocator.free(buf);

    std.debug.print("response - {s}\n", .{buf});
}
