const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const libpng_enabled = b.option(bool, "enable-libpng", "Build libpng") orelse false;

    const lib = b.addStaticLibrary(.{
        .name = "freetype",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    if (target.result.os.tag == .linux) {
        lib.linkSystemLibrary("m");
    }

    const zlib_dep = b.dependency("zlib", .{
        .target = target,
        .optimize = optimize,
    });
    lib.linkLibrary(zlib_dep.artifact("z"));
    if (libpng_enabled) {
        const libpng_dep = b.dependency("libpng", .{
            .target = target,
            .optimize = optimize,
        });
        lib.linkLibrary(libpng_dep.artifact("png"));
    }

    lib.addIncludePath(b.path("upstream/include"));

    var flags = try std.BoundedArray([]const u8, 64).init(0);
    try flags.appendSlice(&.{
        "-DFT2_BUILD_LIBRARY",

        "-DFT_CONFIG_OPTION_SYSTEM_ZLIB=1",

        "-DHAVE_UNISTD_H",
        "-DHAVE_FCNTL_H",

        "-fno-sanitize=undefined",
    });
    if (libpng_enabled) try flags.append("-DFT_CONFIG_OPTION_USE_PNG=1");
    lib.addCSourceFiles(.{
        .files = srcs,
        .flags = flags.slice(),
    });

    switch (target.result.os.tag) {
        .linux => lib.addCSourceFile(.{
            .file = b.path("upstream/builds/unix/ftsystem.c"),
            .flags = flags.slice(),
        }),
        .windows => lib.addCSourceFile(.{
            .file = b.path("upstream/builds/windows/ftsystem.c"),
            .flags = flags.slice(),
        }),
        else => lib.addCSourceFile(.{
            .file = b.path("upstream/src/base/ftsystem.c"),
            .flags = flags.slice(),
        }),
    }
    switch (target.result.os.tag) {
        .windows => {
            lib.addCSourceFiles(.{
                .files = &.{
                    "upstream/builds/windows/ftdebug.c",
                },
                .flags = flags.slice(),
            });
            lib.addWin32ResourceFile(.{
                .file = b.path("upstream/src/base/ftver.rc"),
            });
        },
        else => lib.addCSourceFile(.{
            .file = b.path("upstream/src/base/ftdebug.c"),
            .flags = flags.slice(),
        }),
    }

    lib.installHeader(b.path("include/freetype-zig.h"), "freetype-zig.h");
    lib.installHeader(b.path("upstream/include/ft2build.h"), "ft2build.h");
    lib.installHeadersDirectory(b.path("upstream/include/freetype"), "freetype", .{});

    b.installArtifact(lib);
}

const headers = &.{
    "png.h",
    "pngconf.h",
    "pngdebug.h",
    "pnginfo.h",
    "pngpriv.h",
    "pngstruct.h",
};

const srcs = &.{
    "upstream/src/autofit/autofit.c",
    "upstream/src/base/ftbase.c",
    "upstream/src/base/ftbbox.c",
    "upstream/src/base/ftbdf.c",
    "upstream/src/base/ftbitmap.c",
    "upstream/src/base/ftcid.c",
    "upstream/src/base/ftfstype.c",
    "upstream/src/base/ftgasp.c",
    "upstream/src/base/ftglyph.c",
    "upstream/src/base/ftgxval.c",
    "upstream/src/base/ftinit.c",
    "upstream/src/base/ftmm.c",
    "upstream/src/base/ftotval.c",
    "upstream/src/base/ftpatent.c",
    "upstream/src/base/ftpfr.c",
    "upstream/src/base/ftstroke.c",
    "upstream/src/base/ftsynth.c",
    "upstream/src/base/fttype1.c",
    "upstream/src/base/ftwinfnt.c",
    "upstream/src/bdf/bdf.c",
    "upstream/src/bzip2/ftbzip2.c",
    "upstream/src/cache/ftcache.c",
    "upstream/src/cff/cff.c",
    "upstream/src/cid/type1cid.c",
    "upstream/src/gzip/ftgzip.c",
    "upstream/src/lzw/ftlzw.c",
    "upstream/src/pcf/pcf.c",
    "upstream/src/pfr/pfr.c",
    "upstream/src/psaux/psaux.c",
    "upstream/src/pshinter/pshinter.c",
    "upstream/src/psnames/psnames.c",
    "upstream/src/raster/raster.c",
    "upstream/src/sdf/sdf.c",
    "upstream/src/sfnt/sfnt.c",
    "upstream/src/smooth/smooth.c",
    "upstream/src/svg/svg.c",
    "upstream/src/truetype/truetype.c",
    "upstream/src/type1/type1.c",
    "upstream/src/type42/type42.c",
    "upstream/src/winfonts/winfnt.c",
};
