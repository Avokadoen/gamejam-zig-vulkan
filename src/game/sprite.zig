const std = @import("std");
const builtin = @import("builtin");
const render2d = @import("../render2d/render2d.zig");

const Vec2 = @import("zlm").Vec2;
const texture = @import("texture.zig"); 

pub const Sprites = enum {
    map,
    player_castle,
    enemy_castle,
    spawn_btn,
    sword_man_prototype,
    player_sprite,
    enemy_sprite,
};

pub const team_size: usize = 5000;

const sprite_count = blk: {
    const global_count = @typeInfo(Sprites).Enum.fields.len;
    break :blk (global_count - 2) + team_size * 2;
};

var sprites: [sprite_count]render2d.Sprite = undefined; 

pub inline fn createAllSprites(api: *render2d.InitializedApi, w_width: f32, w_height: f32) !void {
    // create map background sprite
    getGlobal(.map).* = try api.createSprite(
        texture.get(.map), 
        Vec2.new(0, 0), 
        0, 
        Vec2.new(w_width, w_height)
    );

    // create player castle sprite
    getGlobal(.player_castle).* = try api.createSprite(
        texture.get(.castle_idle), 
        Vec2.new(800, -350), 
        0, 
        Vec2.new(
            texture.get(.castle_idle).width * 2, 
            texture.get(.castle_idle).height * 2
        )
    );

    // create enemy castle sprite
    getGlobal(.enemy_castle).* = try api.createSprite(
        texture.get(.castle_idle), 
        Vec2.new(-800, 390), 
        0, 
        Vec2.new(
            texture.get(.castle_idle).width * 2, 
            texture.get(.castle_idle).height * 2
        )
    );

    getGlobal(.spawn_btn).* = try api.createSprite(
        texture.get(.btn_idle), 
        Vec2.new(0, 0), 
        0, 
        Vec2.new(
            texture.get(.btn_idle).width * 4, 
            texture.get(.btn_idle).height * 4
        )
    );

    getGlobal(.sword_man_prototype).* = try api.createSprite(
        texture.get(.unit0), 
        Vec2.new(-20000, 0), 
        0, 
        Vec2.new(
            texture.get(.unit0).width * 0.5, 
            texture.get(.unit0).height * 0.5
        )
    ); 

    {
        var i: usize = 0;
        while (i < team_size) : (i += 1) {
            getPlayerUnit(i).* = try api.createSprite(
                texture.get(.unit0), 
                Vec2.new(-20000, 0), 
                0, 
                Vec2.new(
                    texture.get(.unit0).width * 0.5, 
                    texture.get(.unit0).height * 0.5
                )
            ); 
        }
    }

    {
        var i: usize = 0;
        while (i < team_size) : (i += 1) {
            getEnemyUnit(i).* = try api.createSprite(
                texture.get(.unit0), 
                Vec2.new(-20000, 0), 
                0, 
                Vec2.new(
                    texture.get(.unit0).width * 0.5, 
                    texture.get(.unit0).height * 0.5
                )
            ); 
        }
    }
}

pub inline fn getGlobal(comptime sprite: Sprites) *render2d.Sprite {
    comptime {
        const value = @enumToInt(sprite);
        if (value < @enumToInt(Sprites.player_sprite)) {
            return &sprites[value];
        } else {
            @compileError("sprite is not a global");
        }
    }
}

pub fn getPlayerUnit(number: usize) *render2d.Sprite {
    return &sprites[@enumToInt(Sprites.player_sprite) + number];
}

pub fn getEnemyUnit(number: usize) *render2d.Sprite {
    return &sprites[@enumToInt(Sprites.enemy_sprite) + number];
}
