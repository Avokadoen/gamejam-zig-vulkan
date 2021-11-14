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
    health_bar,
    health_bar_fill,
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

    .{ "health_bar",    "../assets/images/gui/healthbar.png" },
    .{ "health_bar_fill",    "../assets/images/gui/healthbar_fill.png" },
});

var texture_handles: [TexturePath.kvs.len]render2d.TextureHandle = undefined;

pub fn loadAllTextures(api: *render2d.InitializedApi) !void {
    const texture_info = @typeInfo(Texture).Enum;
    inline for(texture_info.fields) |field| {
        texture_handles[field.value] = try api.loadTexture(TexturePath.get(field.name).?);
    }
}

pub inline fn get(texture: Texture) render2d.TextureHandle {
    return texture_handles[@enumToInt(texture)];
}
