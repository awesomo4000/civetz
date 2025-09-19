# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

civetz is a cross-platform web framework for Zig built on CivetWeb. It aims to combine the maturity and portability of CivetWeb (a proven C web server) with modern Zig to create a framework that works on Windows, Linux, and macOS with a clean, Zig-native API.

## Development Commands

### Build
```bash
# Build the project
zig build

# Run the application
zig build run

# Run tests
zig build test

# Run tests with fuzzing
zig build test --fuzz
```

## Architecture & Structure

### Layered Architecture
```
┌─────────────────────────────┐
│     Zig Application Layer   │  <- User applications
├─────────────────────────────┤
│     civetz Framework        │  <- Middleware, Router, Handlers (Zig)
├─────────────────────────────┤
│     CivetWeb (C)            │  <- HTTP/WebSocket transport
├─────────────────────────────┤
│     OS (Win/Linux/Mac)      │  <- Native networking
└─────────────────────────────┘
```

### Core Components (Planned)
- **src/civetweb.zig** - Low-level bindings to CivetWeb C library
- **src/server.zig** - Server abstraction layer
- **src/router.zig** - Routing system with path parameters
- **src/context.zig** - Request/response context
- **src/middleware.zig** - Middleware pipeline support

### Build Configuration
- **build.zig** - Main build configuration with executable and module definitions
- **build.zig.zon** - Package manifest with dependencies (currently no external dependencies)
- Module "civetz" exposed for import with root at src/root.zig
- Executable defined with entry point at src/main.zig

## Implementation Status

### Current State
- Basic project structure with Zig build system configured
- Module and executable scaffolding in place
- No CivetWeb integration yet

### Next Steps (from PLAN.md)
1. Integrate CivetWeb as dependency (git submodule or Zig package manager)
2. Configure build.zig to compile CivetWeb C files
3. Create low-level C bindings
4. Build Zig abstraction layer (Server, Router, Context)
5. Implement middleware system

## Technical Decisions

### Memory Management
- Use arena allocators per request
- Pool allocators for connection buffers
- Let CivetWeb handle connection lifecycle

### Threading Model
- CivetWeb manages threads (num_threads option)
- Zig handlers must be thread-safe

### Platform Support
- Primary targets: Windows, Linux, macOS
- Link with ws2_32 on Windows, pthread on Unix
- Abstract socket and path separator differences

## Performance Goals
- < 10% overhead vs raw CivetWeb
- 50k+ requests/second on modest hardware
- < 10MB memory for basic server
- < 1ms latency for simple requests

## Testing Strategy
- Unit tests for individual components (router, middleware, context)
- Integration tests with actual HTTP requests
- Platform-specific CI/CD testing
- Performance comparison with raw CivetWeb baseline

## Dependencies
- Zig 0.15.1 or later (minimum version)
- CivetWeb (to be added)
- System libraries: ws2_32 (Windows), pthread (Unix)