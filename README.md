# civetz

A cross-platform web framework for Zig built on CivetWeb.

## Overview

civetz combines the maturity and portability of CivetWeb (a proven C web server) with modern Zig to create a framework that:
- Works on Windows, Linux, and macOS
- Provides a clean, Zig-native API
- Supports middleware and routing
- Maintains excellent performance
- Uses MIT licensing throughout

## Architecture

```
┌─────────────────────────────┐
│     Zig Application Layer   │  <- Your app
├─────────────────────────────┤
│     civetz Framework        │  <- Middleware, Router, Handlers (Zig)
├─────────────────────────────┤
│     CivetWeb (C)            │  <- HTTP/WebSocket transport
├─────────────────────────────┤
│     OS (Win/Linux/Mac)      │  <- Native networking
└─────────────────────────────┘
```

## Why CivetWeb + Zig?

**CivetWeb provides:**
- 10+ years of production use
- True cross-platform support (including Windows)
- MIT license
- WebSocket support
- SSL/TLS support
- Small footprint (~200KB)
- Simple C API

**Zig provides:**
- Modern language features
- Excellent C interop
- Memory safety
- Comptime metaprogramming for routing
- Cross-compilation

## Goals

1. **Easy to use** - Flask/Express-like API in Zig
2. **Production ready** - Built on battle-tested CivetWeb
3. **Cross-platform** - Windows, Linux, macOS first-class support
4. **Performant** - Minimal overhead over raw CivetWeb
5. **Extensible** - Middleware system for composition

## Planned Features

### Phase 1: Core (What we're building now)
- [ ] CivetWeb integration
- [ ] Basic request/response handling
- [ ] Routing with path parameters
- [ ] Static file serving

### Phase 2: Middleware & Features
- [ ] Middleware pipeline
- [ ] JSON parsing/generation
- [ ] Form data parsing
- [ ] Cookie handling
- [ ] Sessions

### Phase 3: Advanced
- [ ] WebSocket support
- [ ] Server-Sent Events (SSE)
- [ ] File uploads
- [ ] Rate limiting
- [ ] Compression

## Example API (Planned)

```zig
const std = @import("std");
const civetz = @import("civetz");

pub fn main() !void {
    var app = try civetz.App.init(allocator);
    defer app.deinit();

    // Middleware
    app.use(civetz.middleware.logger());
    app.use(civetz.middleware.cors());

    // Routes
    app.get("/", index);
    app.get("/api/users/:id", getUser);
    app.post("/api/users", createUser);

    // Static files
    app.static("/public", "public/");

    // Start server
    try app.listen(8080);
}

fn index(ctx: *civetz.Context) !void {
    try ctx.html("Welcome to civetz!");
}

fn getUser(ctx: *civetz.Context) !void {
    const id = ctx.param("id");
    const user = try fetchUser(id);
    try ctx.json(user);
}
```

## Development Plan

1. **Setup CivetWeb** - Download, compile, link
2. **Create C bindings** - Wrap CivetWeb's C API
3. **Build Zig layer** - Router, Context, Response types
4. **Add middleware** - Support chaining handlers
5. **Test platforms** - Verify Windows, Linux, macOS

## Building

```bash
zig build

# Run example
zig build run

# Run tests
zig build test
```

## License

MIT