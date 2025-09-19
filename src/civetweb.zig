const std = @import("std");

// Manual C bindings for CivetWeb
pub const mg_context = opaque {};
pub const mg_connection = opaque {};
pub const mg_callbacks = opaque {};

pub const mg_header = extern struct {
    name: [*:0]const u8,
    value: [*:0]const u8,
};

pub const mg_request_info = extern struct {
    request_method: [*:0]const u8,
    request_uri: [*:0]const u8,
    local_uri: [*:0]const u8,
    uri: [*:0]const u8,  // Deprecated, use local_uri
    http_version: [*:0]const u8,
    query_string: [*:0]const u8,
    remote_user: [*:0]const u8,
    remote_addr: [48]u8,
    content_length: i64,
    remote_port: c_int,
    is_ssl: c_int,
    user_data: ?*anyopaque,
    conn_data: ?*anyopaque,
    num_headers: c_int,
    http_headers: [64]mg_header,
    client_cert: ?*anyopaque,
    acceptedWebSocketSubprotocol: [*:0]const u8,
};

pub const mg_request_handler = *const fn (conn: ?*mg_connection, cbdata: ?*anyopaque) callconv(.c) c_int;

// External function declarations
pub extern fn mg_start(callbacks: ?*const mg_callbacks, user_data: ?*anyopaque, options: [*]const [*:0]const u8) ?*mg_context;
pub extern fn mg_stop(ctx: *mg_context) void;
pub extern fn mg_set_request_handler(ctx: *mg_context, uri: [*:0]const u8, handler: mg_request_handler, cbdata: ?*anyopaque) void;
pub extern fn mg_get_request_info(conn: *mg_connection) *const mg_request_info;
pub extern fn mg_get_header(conn: *mg_connection, name: [*:0]const u8) ?[*:0]const u8;
pub extern fn mg_printf(conn: *mg_connection, fmt: [*:0]const u8, ...) c_int;
pub extern fn mg_write(conn: *mg_connection, buf: [*]const u8, len: usize) c_int;
pub extern fn mg_set_user_connection_data(conn: *mg_connection, data: ?*anyopaque) void;
pub extern fn mg_get_user_connection_data(conn: *mg_connection) ?*anyopaque;

// High-level Zig wrapper
pub const Server = struct {
    ctx: *mg_context,

    pub fn init(options: []const ?[*:0]const u8) !Server {
        // Cast to the C expected type
        const opts_ptr = @as([*]const [*:0]const u8, @ptrCast(options.ptr));

        // Debug: print options
        std.debug.print("Starting CivetWeb with options:\n", .{});
        var i: usize = 0;
        while (i < options.len) : (i += 1) {
            if (options[i]) |opt| {
                std.debug.print("  [{d}] = {s}\n", .{i, opt});
            } else {
                std.debug.print("  [{d}] = null\n", .{i});
                break;
            }
        }

        const ctx = mg_start(null, null, opts_ptr);
        if (ctx == null) {
            std.debug.print("mg_start returned null - check if port is already in use\n", .{});
            return error.ServerInitFailed;
        }
        return Server{ .ctx = ctx.? };
    }

    pub fn deinit(self: *Server) void {
        mg_stop(self.ctx);
    }

    pub fn addHandler(self: *Server, uri: [*:0]const u8, handler: mg_request_handler, user_data: ?*anyopaque) void {
        mg_set_request_handler(self.ctx, uri, handler, user_data);
    }
};

pub const Request = struct {
    conn: *mg_connection,

    pub fn getMethod(self: Request) []const u8 {
        const info = mg_get_request_info(self.conn);
        return std.mem.span(info.request_method);
    }

    pub fn getUri(self: Request) []const u8 {
        const info = mg_get_request_info(self.conn);
        return std.mem.span(info.local_uri);
    }

    pub fn getHeader(self: Request, name: [*:0]const u8) ?[]const u8 {
        const value = mg_get_header(self.conn, name);
        if (value == null) return null;
        return std.mem.span(value.?);
    }

    pub fn sendResponse(self: Request, status: u32, content_type: [*:0]const u8, body: []const u8) void {
        _ = mg_printf(self.conn,
            "HTTP/1.1 %d OK\r\n" ++
            "Content-Type: %s\r\n" ++
            "Content-Length: %d\r\n" ++
            "\r\n",
            status, content_type, body.len);
        _ = mg_write(self.conn, body.ptr, body.len);
    }
};

pub fn makeHandler(comptime handler_fn: fn(Request) void) mg_request_handler {
    return struct {
        fn handle(conn: ?*mg_connection, user_data: ?*anyopaque) callconv(.c) c_int {
            _ = user_data;
            if (conn) |c| {
                handler_fn(Request{ .conn = c });
                return 200;
            }
            return 500;
        }
    }.handle;
}