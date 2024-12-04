const std = @import("std");
const ArrayList = std.ArrayList;

pub const DayResult = struct {
    part1: u64,
    part2: u64,
};

pub fn day1(allocator: std.mem.Allocator, file: std.fs.File) !DayResult {
    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

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
        const line = reader.readUntilDelimiterAlloc(allocator, '\n', 1024) catch |err| switch (err) {
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

    var part1: u64 = 0;
    for (0..first_numbers.items.len) |i| {
        if (first_numbers.items[i] > second_numbers.items[i]) {
            part1 += first_numbers.items[i] - second_numbers.items[i];
        } else {
            part1 += second_numbers.items[i] - first_numbers.items[i];
        }
    }

    var second_hash = std.hash_map.AutoHashMap(u64, u64).init(allocator);
    defer second_hash.deinit();

    for (0..second_numbers.items.len) |i| {
        if (second_hash.get(second_numbers.items[i])) |cnt| {
            second_hash.put(second_numbers.items[i], cnt + 1) catch unreachable;
        } else {
            second_hash.put(second_numbers.items[i], 1) catch unreachable;
        }
    }

    var part2: u64 = 0;
    for (first_numbers.items) |key| {
        if (second_hash.get(key)) |cnt| {
            part2 += key * cnt;
        }
    }
    return DayResult{
        .part1 = part1,
        .part2 = part2,
    };
}

pub fn day2(allocator: std.mem.Allocator, file: std.fs.File) !DayResult {
    var buf_reader = std.io.bufferedReader(file.reader());
    var reader = buf_reader.reader();
    var part1: u64 = 0;
    while (true) {
        const line = reader.readUntilDelimiterAlloc(allocator, '\n', 1024) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        defer allocator.free(line);
        var iter = std.mem.split(u8, line, " ");
        var last_level = try std.fmt.parseInt(i64, iter.next().?, 10);
        var direction: i8 = 0;
        var valid = true;
        while (iter.next()) |unparsed_level| {
            const level = try std.fmt.parseInt(i64, unparsed_level, 10);
            const delta: i64 = level - last_level;
            if (delta == 0) {
                // std.debug.print("the following line is invalid because delta is 0: {s}\n", .{line});
                valid = false;
                break; // numbers were equal
            }

            const pos: i8 = @intFromBool((delta > 0));
            const neg: i8 = @intFromBool((delta < 0));
            const current_direction: i8 = pos - neg;
            if (direction == 0 and delta * current_direction <= 3) {
                direction = current_direction;
                last_level = level;
                continue;
            } else if (direction != current_direction) {
                // std.debug.print("the following line is invalid because direction changes: {s}\n", .{line});
                valid = false;
                break; // direction changes
            } else if (@abs(delta) > 3) {
                // std.debug.print("the following line is invalid because delta is too large: {s}\n", .{line});
                valid = false;
                break; // delta is too large
            }
            last_level = level;
        }
        if (valid) {
            part1 += 1;
        }
    }

    try file.seekTo(0);
    buf_reader = std.io.bufferedReader(file.reader());
    reader = buf_reader.reader();

    var part2: u64 = 0;
    while (true) {
        const line = reader.readUntilDelimiterAlloc(allocator, '\n', 1024) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        defer allocator.free(line);
        var iter = std.mem.split(u8, line, " ");
        var last_level = try std.fmt.parseInt(i64, iter.next().?, 10);
        var direction: i8 = 0;
        var valid = true;
        var used_hallpass = false;
        while (iter.next()) |unparsed_level| {
            const level = try std.fmt.parseInt(i64, unparsed_level, 10);
            // std.debug.print("level: {d}\n", .{level});
            const delta: i64 = level - last_level;
            if (delta == 0) {
                if (!used_hallpass) {
                    // std.debug.print("Using hall pass for line: {s}\n", .{line});
                    used_hallpass = true;
                    continue;
                }
                // std.debug.print("the following line is invalid because delta is 0: {s}\n", .{line});
                valid = false;
                break; // numbers were equal
            }

            const pos: i8 = @intFromBool((delta > 0));
            const neg: i8 = @intFromBool((delta < 0));
            const current_direction: i8 = pos - neg;
            if (direction == 0 and delta * current_direction <= 3) {
                direction = current_direction;
                last_level = level;
                continue;
            } else if (direction != current_direction) {
                if (!used_hallpass) {
                    // std.debug.print("Using hall pass for line: {s}\n", .{line});
                    used_hallpass = true;
                    continue;
                }
                // std.debug.print("the following line is invalid because direction changes: {s}\n", .{line});
                valid = false;
                break; // direction changes
            } else if (@abs(delta) > 3) {
                if (!used_hallpass) {
                    // std.debug.print("Using hall pass for line: {s}\n", .{line});
                    used_hallpass = true;
                    continue;
                }
                // std.debug.print("the following line is invalid because delta is too large: {s}\n", .{line});
                valid = false;
                break; // delta is too large
            }
            last_level = level;
        }
        if (valid and used_hallpass) {
            std.debug.print("Used hall pasd which made line: {s} valid\n", .{line});
            part2 += 1;
        } else if (valid) {
            std.debug.print("Didn't need hall pass for line: {s}\n", .{line});
            part2 += 1;
        } else if (!valid and used_hallpass) {
            std.debug.print("Used hall pass for line: {s} but it was invalid\n", .{line});
        }
    }

    return DayResult{
        .part1 = part1,
        .part2 = part2,
    };
}

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
        std.debug.print("Usage: {s} <day number>\n", .{args[0]});
        std.process.exit(1);
    }

    // Parse the integer from args[1]
    const day_num = try std.fmt.parseInt(i32, args[1], 10);
    std.debug.print("Running Day {d}\n", .{day_num});

    // Create the file path
    var path_buffer: [100]u8 = undefined;
    const filepath = try std.fmt.bufPrint(&path_buffer, "data/day{d}.data", .{day_num});

    // Open and read the file
    const file = try std.fs.cwd().openFile(filepath, .{});
    defer file.close();

    // Create a buffer for reading
    const result: DayResult = switch (day_num) {
        1 => try day1(allocator, file),
        2 => try day2(allocator, file),
        else => unreachable,
    };

    std.debug.print("Part 1: {d}\n", .{result.part1});
    std.debug.print("Part 2: {d}\n", .{result.part2});
}
