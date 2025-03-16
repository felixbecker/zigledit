const std = @import("std");
const currentTarget = @import("builtin").target;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "opengltest",
        .root_source_file = .{ .cwd_relative = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    switch (currentTarget.os.tag) {
        .macos => {
            // SDKROOT aus der Umgebung lesen
            const sdkroot = std.process.getEnvVarOwned(b.allocator, "SDKROOT") catch |err| {
                std.debug.print("Fehler beim Lesen von SDKROOT: {}\n", .{err});
                std.process.exit(1);
            };
            defer b.allocator.free(sdkroot);

            // OpenGL Framework-Pfad hinzufügen
            // OpenGL Framework-Pfad hinzufügen
            const framework_path = try std.mem.join(
                b.allocator,
                "/",
                &[_][]const u8{ sdkroot, "System/Library/Frameworks" },
            );
            defer b.allocator.free(framework_path);
            exe.addFrameworkPath(.{ .cwd_relative = framework_path });

            exe.linkFramework("OpenGL");
            exe.linkSystemLibrary("glfw");
            exe.linkLibC();
        },

        else => {
            @panic("don't know how to build on your system");
        },
    }

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
    // b.installArtifact(exe);

    // const run_cmd = b.addRunArtifact(exe);
    // run_cmd.step.dependOn(b.getInstallStep());

    // const run_step = b.step("run", "Run the app");
    // run_step.dependOn(&run_cmd.step);
}

// pub fn build(b: *std.Build) void {
//     const target = b.standardTargetOptions(.{});
//     const optimize = b.standardOptimizeOption(.{});

//     const exe = b.addExecutable(.{
//         .name = "Lesson01",
//         .root_source_file = .{ .path = "src/main.zig" },
//         .target = target,
//         .optimize = optimize,
//     });

//     // GLFW als System-Bibliothek einbinden
//     exe.linkSystemLibrary("glfw");

//     // OpenGL Framework für macOS
//     if (target.isDarwin()) {
//         exe.linkFramework("OpenGL");
//     } else if (target.isLinux()) {
//         exe.linkSystemLibrary("GL");
//     }

//     // Installation und Run-Step
//     b.installArtifact(exe);

//     const run_cmd = b.addRunArtifact(exe);
//     run_cmd.step.dependOn(b.getInstallStep());

//     const run_step = b.step("run", "Run the app");
//     run_step.dependOn(&run_cmd.step);
// }
