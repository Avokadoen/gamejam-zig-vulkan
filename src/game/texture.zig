const std = @import("std");
const render2d = @import("../render2d/render2d.zig");

pub const Texture = enum {
    // sword man
    sword_man_idle,
    sword_man_move,
    sword_man_attack,

    // Lasergoblin
    laser_goblin_move0,
    laser_goblin_move1,

    laser_goblin_attack0,
    laser_goblin_attack1,
    laser_goblin_attack2,

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
    .{ "sword_man_idle",        "../assets/images/units/SwordMan/sword_man_idle.png" },
    .{ "sword_man_move",        "../assets/images/units/SwordMan/sword_man_move.png" },
    .{ "sword_man_attack",      "../assets/images/units/SwordMan/sword_man_attack.png" },

    .{ "laser_goblin_move0",    "../assets/images/units/LaserGoblin/Image20000.png" },
    .{ "laser_goblin_move1",    "../assets/images/units/LaserGoblin/Image20001.png" },
    .{ "laser_goblin_attack0",  "../assets/images/units/LaserGoblin/Image20002.png" },
    .{ "laser_goblin_attack1",  "../assets/images/units/LaserGoblin/Image20003.png" },
    .{ "laser_goblin_attack2",  "../assets/images/units/LaserGoblin/Image20004.png" },

    .{ "map",                   "../assets/images/levels/map.png" },
    .{ "castle_idle",           "../assets/images/structures/castle0000.png" },
    .{ "castle_spawn",          "../assets/images/structures/castle0001.png" },

    .{ "btn_idle",              "../assets/images/gui/test_btn_idle.png" },
    .{ "btn_click",             "../assets/images/gui/test_btn_clicked.png" },

    .{ "health_bar",            "../assets/images/gui/healthbar.png" },
    .{ "health_bar_fill",       "../assets/images/gui/healthbar_fill.png" },
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
