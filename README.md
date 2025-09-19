# civetz

Zig web framework built on CivetWeb and mbedTLS.

## Build

```bash
# Build
zig build

# Run
zig build run

# Release builds
zig build --release=fast
zig build --release=small
```

## Usage

```zig
const std = @import("std");
const civetz = @import("civetz");

fn indexHandler(req: civetz.Request) void {
    req.sendResponse(200, "text/html", "<h1>Hello</h1>");
}

pub fn main() !void {
    const options = [_]?[*:0]const u8{
        "listening_ports", "8090",
        "num_threads", "4",
        null,
    };

    var server = try civetz.Server.init(&options);
    defer server.deinit();

    server.addHandler("/", civetz.makeHandler(indexHandler), null);

    while (true) {
        std.Thread.sleep(1_000_000_000);
    }
}
```

## Platform Support

- Windows (x86_64, aarch64)
- Linux (x86_64, aarch64)
- macOS (x86_64, aarch64)
- FreeBSD (x86_64, aarch64)
- NetBSD (x86_64, aarch64)

## License

MIT