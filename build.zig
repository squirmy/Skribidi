const std = @import("std");

// const version = std.SemanticVersion.parse(@import("build.zig.zon").version) catch unreachable;
const version = std.SemanticVersion{ .major = 0, .minor = 1, .patch = 0 };

pub fn build(b: *std.Build) !void {
    const upstream = b.dependency("Skribidi", .{});
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const src_dir = upstream.path("src");
    const include_dir = upstream.path("include");
    const test_dir = upstream.path("test");
    const example_dir = upstream.path("example");

    const lib = b.addLibrary(.{
        .name = "Skribidi",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
        .version = version,
    });
    lib.addIncludePath(include_dir);
    lib.addCSourceFiles(.{
        .root = src_dir,
        .files = source_files,
    });
    for (skribidi_dependencies) |dep_name| {
        const dep = b.dependency(dep_name, .{ .target = target, .optimize = optimize });
        lib.linkLibrary(dep.artifact(dep_name));
    }
    for (header_files) |header|
        lib.installHeader(include_dir.path(b, header), header);
    b.installArtifact(lib);

    // copy the test data directory to a temp folder when running tests or the example
    const test_data_wf = b.addWriteFiles();
    _ = test_data_wf.addCopyDirectory(example_dir.path(b, "data"), "data", .{});

    const test_step = b.step("test", "Run tests");
    {
        const test_exe = b.addExecutable(.{
            .name = "skribidi_test",
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
            }),
        });
        test_exe.linkLibrary(lib);
        test_exe.addIncludePath(src_dir);
        test_exe.addCSourceFiles(.{ .files = test_files, .root = test_dir });

        const run_test = b.addRunArtifact(test_exe);

        run_test.step.dependOn(&test_data_wf.step);
        run_test.setCwd(test_data_wf.getDirectory());
        test_step.dependOn(&run_test.step);
    }

    const example_step = b.step("example", "Build example");
    {
        const example_exe = b.addExecutable(.{
            .name = "skribidi_example",
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
            }),
        });
        example_exe.addIncludePath(upstream.path("extern/glad/include"));
        example_exe.addIncludePath(b.dependency("harfbuzz", .{}).artifact("harfbuzz").getEmittedIncludeTree());
        example_exe.addCSourceFiles(.{ .files = example_files, .root = example_dir });
        example_exe.linkLibrary(lib);
        if (b.lazyDependency("glfw", .{ .target = target, .optimize = optimize })) |dep| {
            example_exe.linkLibrary(dep.artifact("glfw"));
        }
        if (target.result.os.tag == .windows) {
            example_exe.linkSystemLibrary("imm32");
            example_exe.linkSystemLibrary("Comctl32");
        }
        const install_example = b.addInstallArtifact(example_exe, .{});
        const install_data = b.addInstallDirectory(.{ .install_dir = .bin, .install_subdir = "data", .source_dir = example_dir.path(b, "data") });
        example_step.dependOn(&install_example.step);
        example_step.dependOn(&install_data.step);

        const run_example_step = b.step("run-example", "Run example");
        const run_example = b.addRunArtifact(example_exe);
        run_example.step.dependOn(&test_data_wf.step);
        run_example.setCwd(test_data_wf.getDirectory());
        run_example_step.dependOn(&run_example.step);
    }
}

const skribidi_dependencies: []const []const u8 = &.{
    "harfbuzz",
    "SheenBidi",
    "libunibreak",
    "budouxc",
};

const source_files: []const []const u8 = &.{
    "skb_canvas.c",
    "skb_common.c",
    "skb_editor.c",
    "skb_font_collection.c",
    "skb_icon_collection.c",
    "skb_image_atlas.c",
    "skb_layout.c",
    "skb_layout_cache.c",
    "skb_rasterizer.c",
};

const header_files: []const []const u8 = &.{
    "skb_canvas.h",
    "skb_common.h",
    "skb_editor.h",
    "skb_font_collection.h",
    "skb_icon_collection.h",
    "skb_image_atlas.h",
    "skb_layout.h",
    "skb_layout_cache.h",
    "skb_rasterizer.h",
};

const test_files: []const []const u8 = &.{
    "test_basic.c",
    "test_canvas.c",
    "test_cpp.cpp",
    "test_editor.c",
    "test_font_collection.c",
    "test_hashtable.c",
    "test_icon_collection.c",
    "test_layout.c",
    "test_layout_cache.c",
    "test_rasterizer.c",
    "test_image_atlas.c",
    "test_tempalloc.c",
    "tester.c",
};

const example_files: []const []const u8 = &.{
    "debug_draw.c",
    "example_cached.c",
    "example_decorations.c",
    "example_fallback.c",
    "example_icons.c",
    "example_richtext.c",
    "example_testbed.c",
    "ime.c",
    "main.c",
    "utils.c",
};
