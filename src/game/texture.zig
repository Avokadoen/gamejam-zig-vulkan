const std = @import("std");
const render2d = @import("../render2d/render2d.zig");

pub const Texture = enum {
    // sword man
    unit0,
    unit1,
    unit2,

    // level specific
    map,
    castle_idle,
    castle_spawn,

    // gui 
    btn_idle,
    btn_click,
};

pub const TexturePath = std.ComptimeStringMap([]const u8, .{
    .{ "unit0", "../assets/images/units/unit0000.png" },
    .{ "unit1", "../assets/images/units/unit0001.png" },
    .{ "unit2", "../assets/images/units/unit0002.png" },

    .{ "map",            "../assets/images/levels/map.png" },
    .{ "castle_idle",    "../assets/images/structures/castle0000.png" },
    .{ "castle_spawn",   "../assets/images/structures/castle0001.png" },

    .{ "btn_idle",       "../assets/images/gui/test_btn_idle.png" },
    .{ "btn_click",    "../assets/images/gui/test_btn_clicked.png" },
});

var texture_handles: [TexturePath.kvs.len]render2d.TextureHandle = undefined;

pub fn loadAllTextures(api: *render2d.InitializedApi) !void {
    // load all textures that we will be using
    texture_handles[@enumToInt(Texture.unit0)] = try api.loadTexture(TexturePath.get(@tagName(.unit0)).?);
    texture_handles[@enumToInt(Texture.unit1)] = try api.loadTexture(TexturePath.get(@tagName(.unit1)).?);
    texture_handles[@enumToInt(Texture.unit2)] = try api.loadTexture(TexturePath.get(@tagName(.unit2)).?);
    texture_handles[@enumToInt(Texture.map)] = try api.loadTexture(TexturePath.get(@tagName(.map)).?);

    texture_handles[@enumToInt(Texture.castle_idle)] = try api.loadTexture(TexturePath.get(@tagName(.castle_idle)).?);
    texture_handles[@enumToInt(Texture.castle_spawn)] = try api.loadTexture(TexturePath.get(@tagName(.castle_spawn)).?);

    texture_handles[@enumToInt(Texture.btn_idle)] = try api.loadTexture(TexturePath.get(@tagName(.btn_idle)).?);
    texture_handles[@enumToInt(Texture.btn_click)] = try api.loadTexture(TexturePath.get(@tagName(.btn_click)).?);
}

pub inline fn get(texture: Texture) render2d.TextureHandle {
    return texture_handles[@enumToInt(texture)];
}
