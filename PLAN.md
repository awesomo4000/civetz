# civetz Implementation Plan

## Immediate Next Steps

### 1. CivetWeb Integration
```bash
# Option A: Git submodule
git submodule add https://github.com/civetweb/civetweb deps/civetweb

# Option B: Zig package manager
zig fetch --save https://github.com/civetweb/civetweb/archive/refs/tags/v1.16.tar.gz
```

### 2. Build Configuration
- Set up build.zig to compile CivetWeb C files
- Configure for Windows, Linux, macOS
- Link with appropriate system libraries (ws2_32 on Windows, pthread on Unix)

### 3. Basic Wrapper Structure
```zig
// src/civetweb.zig - Low-level bindings
pub const c = @cImport({
    @cInclude("civetweb.h");
});

// src/server.zig - Server abstraction
pub const Server = struct {
    context: *c.mg_context,

    pub fn init(options: ServerOptions) !Server {
        // Initialize CivetWeb
    }

    pub fn deinit(self: *Server) void {
        // Cleanup
    }
};

// src/router.zig - Routing layer
pub const Router = struct {
    routes: std.StringHashMap(Handler),

    pub fn get(self: *Router, path: []const u8, handler: Handler) void {
        // Register route
    }
};

// src/context.zig - Request context
pub const Context = struct {
    request: *c.mg_connection,
    params: std.StringHashMap([]const u8),

    pub fn json(self: *Context, value: anytype) !void {
        // Send JSON response
    }
};
```

### 4. First Milestone: Hello World
```zig
const civetz = @import("civetz");

pub fn main() !void {
    var server = try civetz.Server.init(.{
        .port = 8080,
    });
    defer server.deinit();

    server.get("/", struct {
        fn handler(ctx: *civetz.Context) !void {
            try ctx.text("Hello, World!");
        }
    }.handler);

    try server.start();
}
```

## Technical Decisions

### Memory Management
- Use arena allocators per request
- Pool allocators for connection buffers
- Let CivetWeb handle connection lifecycle

### Threading Model
- Let CivetWeb manage threads (num_threads option)
- Zig handlers must be thread-safe
- Consider per-thread state later

### Error Handling
- Wrap CivetWeb errors in Zig error types
- Automatic error responses (500, 404, etc)
- Error middleware for custom handling

### Platform Differences
- Abstract socket differences (Windows vs Unix)
- Handle path separators
- Conditional compilation for platform-specific features

## Testing Strategy

1. **Unit Tests** - Test router, middleware, context separately
2. **Integration Tests** - Full server tests with actual HTTP requests
3. **Platform Tests** - CI/CD on Windows, Linux, macOS
4. **Performance Tests** - Compare with raw CivetWeb baseline

## Performance Goals

- < 10% overhead vs raw CivetWeb
- 50k+ requests/second on modest hardware
- < 10MB memory for basic server
- < 1ms latency for simple requests

## Comparison Targets

We're aiming to be simpler than these while maintaining performance:

- **zap** - No Windows support
- **zzz** - Complex, Linux-focused
- **http.zig** - Lower level
- **crow** - C++, hard to integrate

Our niche: **The easiest cross-platform web framework for Zig**