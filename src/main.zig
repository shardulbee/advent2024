const std = @import("std");
const ArrayList = std.ArrayList;

pub fn main() !void {
    // Get allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Get args
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Check if we have the expected number of arguments
    if (args.len != 2) {
        std.debug.print("Usage: {s} <number>\n", .{args[0]});
        std.process.exit(1);
    }

    // Parse the integer from args[1]
    const day_num = try std.fmt.parseInt(i32, args[1], 10);

    // Create the file path
    var path_buffer: [100]u8 = undefined;
    const filepath = try std.fmt.bufPrint(&path_buffer, "data/day{d}.data", .{day_num});

    // Open and read the file
    const file = try std.fs.cwd().openFile(filepath, .{});
    defer file.close();

    // Create a buffer for reading
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    // Create an ArrayList to store the lines
    var lines = ArrayList([]u8).init(allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    // Read the file line by line
    while (true) {
        const line = in_stream.readUntilDelimiterAlloc(allocator, '\n', 1024) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        try lines.append(line);
    }

    // Create ArrayLists for the numbers
    var first_numbers = ArrayList(u64).init(allocator);
    defer first_numbers.deinit();
    var second_numbers = ArrayList(u64).init(allocator);
    defer second_numbers.deinit();

    // Process each line
    for (lines.items) |line| {
        if (line.len == 0) continue;

        var iter = std.mem.split(u8, line, "   ");
        const first_str = iter.next().?;
        const second_str = iter.next().?;

        const first_num = try std.fmt.parseInt(u64, first_str, 10);
        const second_num = try std.fmt.parseInt(u64, second_str, 10);

        try first_numbers.append(first_num);
        try second_numbers.append(second_num);
    }

    // sort both lists of numbers
    std.mem.sort(u64, first_numbers.items, {}, std.sort.asc(u64));
    std.mem.sort(u64, second_numbers.items, {}, std.sort.asc(u64));

    var sum: u64 = 0;
    for (0..first_numbers.items.len) |i| {
        if (first_numbers.items[i] > second_numbers.items[i]) {
            sum += first_numbers.items[i] - second_numbers.items[i];
        } else {
            sum += second_numbers.items[i] - first_numbers.items[i];
        }
    }

    // Print the result
    std.debug.print("Part 1: {d}\n", .{sum});

    var second_hash = std.hash_map.AutoHashMap(u64, u64).init(allocator);
    defer second_hash.deinit();

    for (0..second_numbers.items.len) |i| {
        if (second_hash.get(second_numbers.items[i])) |cnt| {
            second_hash.put(second_numbers.items[i], cnt + 1) catch unreachable;
        } else {
            second_hash.put(second_numbers.items[i], 1) catch unreachable;
        }
    }

    sum = 0;
    for (first_numbers.items) |key| {
        if (second_hash.get(key)) |cnt| {
            sum += key * cnt;
        }
    }

    std.debug.print("Part 2: {d}\n", .{sum});
}
