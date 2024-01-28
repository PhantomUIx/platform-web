const std = @import("std");
const phantom = @import("phantom");
const Package = if (@hasDecl(@import("root"), "dependencies")) phantom.Sdk.Platform.Step.Package else phantom.platform.Sdk.Step.Package;
const Sdk = @import("../../sdk.zig");
const Self = @This();

base: Package,
compile: *std.Build.Step.Compile,

pub fn create(sdk: *Sdk, options: Package.Options) !*Package {
    const b = sdk.base.owner;
    const self = try b.allocator.create(Self);
    errdefer b.allocator.free(self);

    self.compile = std.Build.Step.Compile.create(b, .{
        .name = options.name,
        .root_module = options.root_module,
        .version = options.version,
        .kind = .exe,
    });

    self.compile.root_module.addImport("phantom", sdk.base.phantom);

    self.base.init(&sdk.base, options, make, &self.compile.root_module);
    self.base.step.dependOn(&self.compile.step);
    return &self.base;
}

fn make(step: *std.Build.Step, _: *std.Progress.Node) !void {
    const pkgStep = @fieldParentPtr(Package, "step", step);
    const self = @fieldParentPtr(Self, "base", pkgStep);

    pkgStep.output_file.path = step.owner.dupe(self.compile.generated_bin.?.path.?);
}
