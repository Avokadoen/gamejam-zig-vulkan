pub const Anim = @import("Anim.zig");
pub const Button = @import("Button.zig");
pub const Move = @import("Move.zig");
pub const Unit = @import("Unit.zig");
pub const Castle = @import("Castle.zig");
pub const HealthBar = @import("HealthBar.zig");

const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Vec2 = @import("zlm").Vec2;
const render2d = @import("../render2d/render2d.zig");
const input = @import("../input.zig");
const texture = @import("texture.zig"); 
const sprite = @import("sprite.zig");

var buttons: ArrayList(Button) = undefined;
var hover_button: ?Button = null;

var swordman_prototype: Unit = undefined;
var laser_goblin_prototype: Unit = undefined;

var player_castle: Castle = undefined;
var enemy_castle: Castle = undefined;

var window_width: f32 = undefined;
var window_height: f32 = undefined;

// ----------------------- INITIALIZATION ----------------------- //

/// load all textures in the game scene
pub const loadAllTextures = texture.loadAllTextures;

/// create all sprites in game scene
pub fn createAllSprites(api: *render2d.InitializedApi, w_width: f32, w_height: f32) !void {
    window_width = w_width;
    window_height = w_height;
    try sprite.createAllSprites(api, w_width, w_height);
}

/// caller must make sure to call deinitUnits
pub fn initAllUnits(allocator: *Allocator) !void {
    // create a test unit for now
    const sword_man_anim_move = [_]render2d.TextureHandle{ texture.get(.sword_man_idle), texture.get(.sword_man_move)};
    const sword_man_anim_attack = [_]render2d.TextureHandle{ texture.get(.sword_man_idle), texture.get(.sword_man_attack)};
    swordman_prototype = try Unit.init(
        allocator, 
        sprite.getGlobal(.sword_man_prototype), 
        100, 25, 100, 50, 0.5, 
        [2][]const render2d.TextureHandle{&sword_man_anim_move, &sword_man_anim_attack}
    );

    const laser_goblin_anim_move = [_]render2d.TextureHandle{ texture.get(.laser_goblin_move0), texture.get(.laser_goblin_move1)};
    const laser_goblin_anim_attack = [_]render2d.TextureHandle{ texture.get(.laser_goblin_attack0), texture.get(.laser_goblin_attack1), texture.get(.laser_goblin_attack2)};

    laser_goblin_prototype = try Unit.init(
        allocator, 
        sprite.getGlobal(.laser_goblin_prototype), 
        50, 10, 30, 300, 1, 
        [2][]const render2d.TextureHandle{&laser_goblin_anim_move, &laser_goblin_anim_attack}
    );

}

/// caller must make sure to call deinitCastles
pub fn initCastles(allocator: *Allocator) !void {
    const caste_anim_idle = [_]render2d.TextureHandle{texture.get(.castle_idle)};
    const caste_anim_attack = [_]render2d.TextureHandle{texture.get(.castle_spawn)};

    player_castle = try Castle.init(
        allocator,
        sprite.getGlobal(.player_castle),
        swordman_prototype,
        laser_goblin_prototype,
        2000, 300, 200, 1.5,
        [2][]const render2d.TextureHandle{&caste_anim_idle, &caste_anim_attack},
        .player
    );

    enemy_castle = try Castle.init(
        allocator,
        sprite.getGlobal(.enemy_castle),
        swordman_prototype,
        laser_goblin_prototype,
        2000, 300, 200, 1.5,
        [2][]const render2d.TextureHandle{&caste_anim_idle, &caste_anim_attack},
        .enemy
    );

    player_castle.setOpponent(&enemy_castle);
    enemy_castle.setOpponent(&player_castle);

}

/// caller must make sure to calle deinitGui
pub fn initGui(allocator: *Allocator) !void {
    buttons = ArrayList(Button).init(allocator);
    try buttons.append(Button.init(
        sprite.getGlobal(.spawn_btn), 
        texture.get(.btn_idle), 
        texture.get(.btn_click), 
        btnCallback
    ));
}

// --------------- TICK ------------------------------------------ //

pub fn globalTick(delta_time: f32) void {
    player_castle.tick(delta_time);
    enemy_castle.tick(delta_time);

    btnCallback();
}


// --------------- DEINITIALIZATION ------------------------------- //

pub fn deinitCastles() void {
    player_castle.deinit();
    enemy_castle.deinit();
}

pub fn deinitUnits() void {
    swordman_prototype.deinit();
}

pub fn deinitGui() void {
    buttons.deinit();
}

// ---------------- INPUT HANDLING -------------------------------- //

fn btnCallback() void {
    player_castle.spawnUnit() catch {};
    enemy_castle.spawnUnit() catch {};
}

/// extend main's mouse button input handling
pub inline fn mouseBtnInputFn(event: input.MouseButtonEvent) void {
    if (event.button == .left) {
        if (hover_button) |*some| {
            if (event.action == .press) {
                some.onClick();
            } else if (event.action == .release) {
                some.onRelease();
            }
        }
    }
}

/// extend main's cursor input handling
pub inline fn cursorPosInputFn(event: input.CursorPosEvent) void {
    const vec_event = Vec2.new(
        @floatCast(f32, event.x) - window_width * 0.5, 
        (@floatCast(f32, event.y) - window_height * 0.5) * -1
    );

    var prev_button = hover_button;
    hover_button = null;

    for (buttons.items) |button| {
        if (button.bound.contains(vec_event)) {
            hover_button = button;
            break;
        }
    }

    // Make sure old button is released if no longer held
    if (prev_button) |prev_some| {
        if (hover_button) |new_some| {
            if(prev_some.sprite.db_id.value == new_some.sprite.db_id.value) {
                return;
            }
        }
        prev_some.onRelease();
    }
}
