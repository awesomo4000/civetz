# Zig 0.14.1 to 0.15.1 Migration Cheatsheet

Zig 0.15.1 introduced **"Writergate"** - one of the most disruptive releases in Zig's history, completely overhauling the standard library's I/O interfaces. This cheatsheet provides concrete FROM → TO patterns for migrating your code, focusing on the most critical changes developers encounter.

## Critical: The .interface Pattern (Never Copy!)

The new I/O interfaces use vtable-based dynamic dispatch with `@fieldParentPtr`. **Copying the interface field breaks this mechanism**, causing undefined behavior.

### ❌ WRONG - Causes Undefined Behavior
```zig
var file_writer = std.fs.File.stdout().writer(&buffer);
var writer_instance = file_writer.interface; // ❌ COPY - BREAKS!
try doSomething(&writer_instance);
```

### ✅ CORRECT - Reference Only
```zig
var file_writer = std.fs.File.stdout().writer(&buffer);
const writer_ptr = &file_writer.interface; // ✅ Reference only
try doSomething(writer_ptr);
```

The interface uses `@fieldParentPtr` internally to access the parent struct. When you copy, the offset calculation points to invalid memory. **This is the #1 migration mistake.**

## I/O Operations - Complete Overhaul

### Basic File Writing

**FROM (0.14.1):**
```zig
const stdout_file = std.io.getStdOut();
const stdout_writer = stdout_file.writer();
var buffered_writer = std.io.bufferedWriter(stdout_writer);
try buffered_writer.writer().print("Hello {}\n", .{42});
try buffered_writer.flush();
```

**TO (0.15.1):**
```zig
var stdout_buffer: [4096]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
const stdout = &stdout_writer.interface;
try stdout.print("Hello {d}\n", .{42});
try stdout.flush(); // Don't forget to flush!
```

### Function Parameters

**FROM (0.14.1):**
```zig
fn writeData(writer: anytype) @TypeOf(writer).Error!void {
    try writer.writeAll("Hello, World!\n");
}
```

**TO (0.15.1):**
```zig
fn writeData(writer: *std.Io.Writer) std.Io.Writer.Error!void {
    try writer.writeAll("Hello, World!\n");
}
```

**Important:** Use `std.Io` (capitalized) not `std.io` - the lowercase version is deprecated and will be removed!

### Reading Files with Buffering

**FROM (0.14.1):**
```zig
const file = try std.fs.cwd().openFile("input.txt", .{});
defer file.close();
const reader = file.reader();
var buffered = std.io.bufferedReader(reader);
const line = try buffered.reader().readUntilDelimiterAlloc(allocator, '\n', 1024);
```

**TO (0.15.1):**
```zig
const file = try std.fs.cwd().openFile("input.txt", .{});
defer file.close();
var buffer: [4096]u8 = undefined;
var file_reader = file.reader(&buffer);
const reader = &file_reader.interface;
const line = try reader.readUntilDelimiterAlloc(allocator, '\n', 1024);
```

### Custom Stream Implementation

**FROM (0.14.1):**
```zig
pub const MyStream = struct {
    data: []const u8,
    pos: usize = 0,
    
    pub fn reader(self: *MyStream) std.io.Reader(*MyStream, ReadError, read) {
        return .{ .context = self };
    }
    
    fn read(self: *MyStream, dest: []u8) ReadError!usize {
        const amt = @min(dest.len, self.data.len - self.pos);
        @memcpy(dest[0..amt], self.data[self.pos..][0..amt]);
        self.pos += amt;
        return amt;
    }
};
```

**TO (0.15.1):**
```zig
pub const MyStream = struct {
    data: []const u8,
    pos: usize = 0,
    reader: std.Io.Reader,
    
    pub fn init(data: []const u8, buffer: []u8) MyStream {
        return .{
            .data = data,
            .reader = .{
                .vtable = &.{
                    .stream = MyStream.stream,
                    .discard = MyStream.discard,
                },
                .buffer = buffer,
                .seek = 0,
                .end = 0,
            },
        };
    }
    
    fn stream(io_reader: *std.Io.Reader, w: *std.Io.Writer, limit: std.Io.Limit) std.Io.Reader.StreamError!usize {
        const self: *MyStream = @alignCast(@fieldParentPtr("reader", io_reader));
        // Implementation...
    }
};
```

## Container Changes - Unmanaged by Default

### ArrayList Migration

**FROM (0.14.1):**
```zig
var list = std.ArrayList(i32).init(allocator);
defer list.deinit();
try list.append(1234);
try list.ensureUnusedCapacity(10);
list.appendAssumeCapacity(5678);
```

**TO (0.15.1) - Default Unmanaged:**
```zig
var list: std.ArrayList(i32) = .{};
// Or more concisely: var list = std.ArrayList(i32){};
defer list.deinit(allocator);
try list.append(allocator, 1234);
try list.ensureUnusedCapacity(allocator, 10);
list.appendAssumeCapacity(5678);
```

**Also remember:**
- `toOwnedSlice()` now needs allocator: `try list.toOwnedSlice(allocator)`
- `errdefer` patterns: `errdefer list.deinit(allocator);`

**TO (0.15.1) - Using Managed Variant:**
```zig
var list = std.array_list.Managed(i32).init(allocator);
defer list.deinit();
try list.append(1234); // Works like 0.14.1
```

### HashMap Changes

**FROM (0.14.1):**
```zig
var map = std.StringHashMap(i32).init(allocator);
defer map.deinit();
try map.put("key", 42);
```

**TO (0.15.1) - Similar pattern, prefer unmanaged:**
```zig
var map: std.StringHashMapUnmanaged(i32) = .{};
defer map.deinit(allocator);
try map.put(allocator, "key", 42);
```

## Format String Changes

### Explicit Format Method Calls

**FROM (0.14.1):**
```zig
std.debug.print("{}", .{std.zig.fmtId("example")});
std.debug.print("{}", .{my_custom_type});
```

**TO (0.15.1):**
```zig
std.debug.print("{f}", .{std.zig.fmtId("example")}); // {f} for format method
std.debug.print("{any}", .{my_custom_type});         // {any} to skip format method
```

### Custom Format Methods

**FROM (0.14.1):**
```zig
pub fn format(
    self: @This(),
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    try writer.print("Custom: {}", .{self.value});
}
```

**TO (0.15.1):**
```zig
pub fn format(self: @This(), writer: *std.Io.Writer) std.Io.Writer.Error!void {
    try writer.print("Custom: {d}", .{self.value});
}
```

## Build System Changes

### Basic Executable
**FROM (0.14.1):**
```zig
const exe = b.addExecutable(.{
    .name = "myapp",
    .root_source_file = b.path("src/main.zig"),
    .target = target,
    .optimize = optimize,
});
```

**TO (0.15.1) - Option 1: Create module separately:**
```zig
const exe_mod = b.createModule(.{
    .root_source_file = b.path("src/main.zig"),
    .target = target,
    .optimize = optimize,
});
const exe = b.addExecutable(.{
    .name = "myapp",
    .root_module = exe_mod,
});
```

**TO (0.15.1) - Option 2: Inline module creation:**
```zig
const exe = b.addExecutable(.{
    .name = "myapp",
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    }),
});
```

### Libraries with Modules
```zig
// Creating a module for use as library and in executable
const my_mod = b.addModule("mylib", .{
    .root_source_file = b.path("src/mylib.zig"),
    .target = target,
    .optimize = optimize,
});
my_mod.addImport("dependency", dep_module);

const lib = b.addLibrary(.{
    .name = "mylib",
    .root_module = my_mod,
    .linkage = .static,
});
```

### Tests
**FROM (0.14.1):**
```zig
const tests = b.addTest(.{
    .root_source_file = b.path("src/main.zig"),
    .target = target,
    .optimize = optimize,
});
```

**TO (0.15.1):**
```zig
const tests = b.addTest(.{
    .root_module = module_to_test,
});
```

## Language-Level Changes

### Removal of usingnamespace

**FROM (0.14.1):**
```zig
pub usingnamespace if (builtin.os.tag == .linux)
    @import("linux.zig")
else if (builtin.os.tag == .windows)
    @import("windows.zig")
else
    struct {};
```

**TO (0.15.1):**
```zig
pub const platform = if (builtin.os.tag == .linux)
    @import("linux.zig")
else if (builtin.os.tag == .windows)
    @import("windows.zig")
else
    @compileError("unsupported platform");
```

### Inline Assembly Clobbers

**FROM (0.14.1):**
```zig
asm volatile ("syscall"
    : [ret] "={rax}" (-> usize),
    : [number] "{rax}" (number),
    : "rcx", "r11"
);
```

**TO (0.15.1):**
```zig
asm volatile ("syscall"
    : [ret] "={rax}" (-> usize),
    : [number] "{rax}" (number),
    : .{ .rcx = true, .r11 = true }
);
```

## HTTP Client/Server Overhaul

### HTTP Server

**FROM (0.14.1):**
```zig
var read_buffer: [8000]u8 = undefined;
var server = std.http.Server.init(connection, &read_buffer);
while (server.state == .ready) {
    var request = try server.receiveHead();
    // Handle request...
}
```

**TO (0.15.1):**
```zig
var recv_buffer: [4000]u8 = undefined;
var send_buffer: [4000]u8 = undefined;
var conn_reader = connection.stream.reader(&recv_buffer);
var conn_writer = connection.stream.writer(&send_buffer);
var server = std.http.Server.init(conn_reader.interface(), &conn_writer.interface);
```

### HTTP Client

**FROM (0.14.1):**
```zig
var request = try client.open(.GET, uri, headers, .{});
defer request.deinit();
try request.send();
try request.wait();
const body = try request.reader().readAllAlloc(allocator, 8192);
```

**TO (0.15.1):**
```zig
var request = try client.request(.GET, uri, headers, .{});
defer request.deinit();
try request.sendBodiless();
var buffer: [4096]u8 = undefined;
const reader = request.reader(&buffer);
const body = try reader.readAllAlloc(allocator, 8192);
```

## Common Migration Gotchas

### ArrayList in Struct Initialization
```zig
// FROM (0.14.1):
pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .items = std.ArrayList(Item).init(allocator),
        .allocator = allocator,
    };
}

// TO (0.15.1):
pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .items = std.ArrayList(Item){},
        .allocator = allocator,
    };
}
```

### Mutable Self for deinit with ArrayLists
```zig
// When a struct contains ArrayLists that need cleanup:
// FROM (0.14.1):
pub fn deinit(self: Plugin) void {
    self.xrefs.deinit();
}

// TO (0.15.1) - Need mutable self!
pub fn deinit(self: *Plugin) void {
    self.xrefs.deinit(self.allocator);
}
```

### AutoArrayHashMap Still Works Differently
```zig
// Note: std.AutoArrayHashMap's deinit() does NOT take allocator
var map = std.AutoArrayHashMap(u32, Plugin).init(allocator);
defer map.deinit();  // No allocator parameter!

// But the values might need cleanup:
var iter = map.iterator();
while (iter.next()) |entry| {
    entry.value_ptr.*.deinit();  // If Plugin has deinit
}
```

### Must Remember to Flush
```zig
// 0.15.1 requires explicit flushing
try writer.print("Important data");
try writer.flush(); // ← Don't forget this!
```

### Adapter for Legacy Code
```zig
// Gradual migration helper
fn useOldApi(old_writer: anytype) !void {
    var adapter = old_writer.adaptToNewApi(&.{});
    const w: *std.Io.Writer = &adapter.new_interface;
    try w.writeAll("Works with new API");
}
```

### Compression API Removed
```zig
// Compression removed - only decompression remains
var decompress_buffer: [std.compress.flate.max_window_len]u8 = undefined;
var decompress: std.compress.flate.Decompress = .init(reader, .zlib, &decompress_buffer);
const decompress_reader: *std.Io.Reader = &decompress.reader;
```

### Error Set Changes
```zig
// FROM: anyerror
fn readFile(path: []const u8) anyerror![]const u8 { }

// TO: Precise error sets
fn readFile(path: []const u8) std.fs.File.OpenError![]const u8 { }
```

## Migration Priority Order

1. **Fix build.zig** - Enable compilation with new module system
2. **Update format strings** - Add `{f}` or `{any}` specifiers
3. **Migrate I/O code** - Replace all reader/writer usage (use `std.Io` not `std.io`!)
4. **Convert containers** - Switch to unmanaged or .Managed variants
5. **Remove usingnamespace** - Replace with explicit imports
6. **Update HTTP code** - Complete rewrite required

## Quick Reference: ArrayList Migration Patterns

| Operation | 0.14.1 | 0.15.1 |
|-----------|--------|--------|
| Init | `.init(allocator)` | `{}` |
| Deinit | `.deinit()` | `.deinit(allocator)` |
| Append | `.append(item)` | `.append(allocator, item)` |
| ToOwnedSlice | `.toOwnedSlice()` | `.toOwnedSlice(allocator)` |
| In struct init | `std.ArrayList(T).init(allocator)` | `std.ArrayList(T){}` |
| errdefer | `errdefer list.deinit()` | `errdefer list.deinit(allocator)` |

## Performance Benefits After Migration

The extensive changes deliver significant performance improvements:
- **5x faster compilation** with x86 backend in debug mode
- **14.6% faster wall time** for typical compilation tasks
- **Eliminated binary bloat** from generic instantiation
- **Better cache performance** with buffer-in-interface design

While migration requires substantial effort, projects report improved performance and cleaner code architecture after completing the transition. The new patterns eliminate hidden allocations and provide more explicit control over memory and I/O operations, aligning with Zig's philosophy of no hidden control flow or allocations.