const std = @import("std");
const civetz = @import("civetz");

fn indexHandler(req: civetz.Request) void {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\    <title>civetz - Zig Web Framework</title>
        \\    <meta charset="UTF-8">
        \\</head>
        \\<body>
        \\    <h1>Welcome to civetz!</h1>
        \\    <p>CivetWeb + mbedTLS + Zig = 🚀</p>
        \\    <p>Visit <a href="/api/hello">/api/hello</a> for JSON response</p>
        \\</body>
        \\</html>
    ;
    req.sendResponse(200, "text/html", html);
}

fn apiHandler(req: civetz.Request) void {
    const json =
        \\{"message": "Hello from civetz!", "framework": "CivetWeb", "language": "Zig"}
    ;
    req.sendResponse(200, "application/json", json);
}

pub fn main() !void {
    std.debug.print("Starting civetz server...\n", .{});

    // CivetWeb configuration options (null-terminated pairs)
    const options = [_]?[*:0]const u8{
        "listening_ports", "8090",
        "num_threads", "4",
        "connection_queue", "100",
        "listen_backlog", "1000",
        "linger_timeout_ms", "0",
        "enable_keep_alive", "yes",
        "tcp_nodelay", "1",
        null, // Options must be null-terminated
    };

    var server = try civetz.Server.init(&options);
    defer server.deinit();

    // Add request handlers
    server.addHandler("/", civetz.makeHandler(indexHandler), null);
    server.addHandler("/api/hello", civetz.makeHandler(apiHandler), null);

    std.debug.print("Server running on http://localhost:8090\n", .{});
    std.debug.print("Press Ctrl+C to stop\n", .{});

    // Keep the server running
    while (true) {
        std.Thread.sleep(1_000_000_000); // Sleep for 1 second
    }
}
