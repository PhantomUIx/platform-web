const std = @import("std");
const Phantom = @import("phantom");

pub const phantomModule = Phantom.Sdk.PhantomModule{
    .provides = .{
        .platforms = .{"web"},
    },
};

pub const phantomPlatform = struct {
    pub const web = @import("src/phantom/platform/backends/web/sdk.zig");
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const no_importer = b.option(bool, "no-importer", "disables the import system (not recommended)") orelse false;
    const no_docs = b.option(bool, "no-docs", "skip installing documentation") orelse false;
    const no_tests = b.option(bool, "no-tests", "skip generating tests") orelse false;

    const phantom = b.dependency("phantom", .{
        .target = target,
        .optimize = optimize,
        .@"no-importer" = no_importer,
        .@"no-docs" = no_docs,
        .@"import-module" = try Phantom.Sdk.ModuleImport.init(&.{}, b.pathFromRoot("src"), b.allocator),
    });

    _ = b.addModule("phantom.platform.web", .{
        .root_source_file = .{ .path = b.pathFromRoot("src/phantom.zig") },
        .imports = &.{
            .{
                .name = "phantom",
                .module = phantom.module("phantom"),
            },
        },
    });

    const sdk = try phantomPlatform.web.create(b, phantom.module("phantom"));
    defer sdk.deinit();

    const pkg_example = sdk.addPackage(.{
        .id = "dev.phantomui.example",
        .name = "example",
        .root_module = .{
            .root_source_file = .{
                .path = b.pathFromRoot("src/example.zig"),
            },
            .target = target,
            .optimize = optimize,
        },
        .kind = .application,
        .version = .{
            .major = 0,
            .minor = 1,
            .patch = 0,
        },
    });

    sdk.installPackage(pkg_example);

    if (!no_tests) {
        const step_test = b.step("test", "Run all unit tests");

        const unit_tests = phantom.artifact("test");

        const run_unit_tests = b.addRunArtifact(unit_tests);
        step_test.dependOn(&run_unit_tests.step);

        if (!no_docs) {
            const docs = b.addInstallDirectory(.{
                .source_dir = unit_tests.getEmittedDocs(),
                .install_dir = .prefix,
                .install_subdir = "docs",
            });

            b.getInstallStep().dependOn(&docs.step);
        }
    }
}
