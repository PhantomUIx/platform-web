const std = @import("std");
const Allocator = std.mem.Allocator;
const phantom = @import("phantom");
const Sdk = if (@hasDecl(@import("root"), "dependencies")) phantom.Sdk.Platform else phantom.platform.Sdk;
const Package = @import("sdk/step/pkg.zig");
const InstallPackage = @import("sdk/step/install-pkg.zig");
const Self = @This();

pub const RenderMode = enum {
    ServerSide,
    ClientSide,
};

pub const GenerationMode = enum {
    Static,
    Served,
};

base: Sdk,
renderMode: RenderMode,
genMode: GenerationMode,

pub fn create(b: *std.Build, phantomModule: *std.Build.Module) !*Sdk {
    const self = try b.allocator.create(Self);
    errdefer b.allocator.destroy(self);

    self.* = .{
        .base = .{
            .vtable = &.{
                .addPackage = addPackage,
                .addInstallPackage = addInstallPackage,
                .deinit = deinit,
            },
            .ptr = self,
            .owner = b,
            .phantom = phantomModule,
        },
        .renderMode = b.option(RenderMode, "render-mode", "Sets whether or no the rendering should be done server side or client side") orelse .ClientSide,
        .genMode = b.option(GenerationMode, "gen-mode", "Sets whether or not the site should be statically generated or should be served") orelse .Static,
    };
    return &self.base;
}

fn addPackage(ctx: *anyopaque, _: *std.Build, options: Sdk.Step.Package.Options) *Sdk.Step.Package {
    const self: *Self = @ptrCast(@alignCast(ctx));
    return Package.create(self, options) catch |e| @panic(@errorName(e));
}

fn addInstallPackage(ctx: *anyopaque, _: *std.Build, pkg: *Sdk.Step.Package) *Sdk.Step.InstallPackage {
    const self: *Self = @ptrCast(@alignCast(ctx));
    return InstallPackage.create(self, pkg) catch |e| @panic(@errorName(e));
}

fn deinit(ctx: *anyopaque) void {
    const self: *Self = @ptrCast(@alignCast(ctx));
    self.base.owner.allocator.destroy(self);
}
