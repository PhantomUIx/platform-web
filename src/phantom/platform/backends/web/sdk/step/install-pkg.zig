const std = @import("std");
const phantom = @import("phantom");
const Package = if (@hasDecl(@import("root"), "dependencies")) phantom.Sdk.Platform.Step.Package else phantom.platform.Sdk.Step.Package;
const InstallPackage = if (@hasDecl(@import("root"), "dependencies")) phantom.Sdk.Platform.Step.InstallPackage else phantom.platform.Sdk.Step.InstallPackage;
const Sdk = @import("../../sdk.zig");
const Self = @This();

base: InstallPackage,
install: *std.Build.Step.InstallArtifact,

pub fn create(sdk: *Sdk, pkg: *Package) !*InstallPackage {
    const b = sdk.base.owner;
    const self = try b.allocator.create(Self);
    errdefer b.allocator.free(self);

    self.base.init(&sdk.base, pkg, make);

    const compile = @fieldParentPtr(@import("pkg.zig"), "base", pkg).compile;
    self.install = b.addInstallArtifact(compile, .{});
    self.base.step.dependOn(&self.install.step);

    return &self.base;
}

fn make(step: *std.Build.Step, _: *std.Progress.Node) !void {
    _ = step;
}
