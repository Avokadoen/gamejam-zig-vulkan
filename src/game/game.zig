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

var buttons: ArrayList(Button) = undefined;
var hover_button: ?Button = null;

var texture_handles: [8]render2d.TextureHandle = undefined;
var sprites: [5]render2d.Sprite = undefined; 
var player_sprites: [1000]render2d.Sprite = undefined;
var enemy_sprites: [1000]render2d.Sprite = undefined;

var unit_move: Move = undefined;
var unit_swordman: Unit = undefined;

var player_castle: Castle = undefined;
var enemy_castle: Castle = undefined;

var window_width: f32 = undefined;
var window_height: f32 = undefined;

// ----------------------- INITIALIZATION ----------------------- //

/// load all textures in the game scene
pub fn loadAllTextures(api: *render2d.InitializedApi) !void {
    // load all textures that we will be using
    texture_handles[0] = try api.loadTexture("../assets/images/units/unit0000.png"[0..]);
    texture_handles[1] = try api.loadTexture("../assets/images/units/unit0001.png"[0..]);
    texture_handles[2] = try api.loadTexture("../assets/images/units/unit0002.png"[0..]);

    texture_handles[3] = try api.loadTexture("../assets/images/levels/map.png"[0..]);
    texture_handles[4] = try api.loadTexture("../assets/images/structures/castle0000.png"[0..]);
    texture_handles[5] = try api.loadTexture("../assets/images/structures/castle0001.png"[0..]);

    texture_handles[6] = try api.loadTexture("../assets/images/gui/test_btn_idle.png"[0..]);
    texture_handles[7] = try api.loadTexture("../assets/images/gui/test_btn_clicked.png"[0..]);
}

/// create all sprites in game scene
pub fn createAllSprites(api: *render2d.InitializedApi, w_width: f32, w_height: f32) !void {
    window_width = w_width;
    window_height = w_height;

    // create map background sprite
    sprites[0] = try api.createSprite(
        texture_handles[3], 
        Vec2.new(0, 0), 
        0, 
        Vec2.new(window_width, window_height)
    );

    // create enemy castle sprite
    sprites[1] = try api.createSprite(
        texture_handles[4], 
        Vec2.new(-800, 390), 
        0, 
        Vec2.new(
            texture_handles[4].width * 2, 
            texture_handles[4].height * 2
        )
    );

    // create player castle sprite
    sprites[2] = try api.createSprite(
        texture_handles[4], 
        Vec2.new(800, -350), 
        0, 
        Vec2.new(
            texture_handles[4].width * 2, 
            texture_handles[4].height * 2
        )
    );

    sprites[3] = try api.createSprite(
        texture_handles[0], 
        Vec2.new(-20000, 0), 
        0, 
        Vec2.new(
            texture_handles[4].width, 
            texture_handles[4].height
        )
    );

    sprites[4] = try api.createSprite(
        texture_handles[6], 
        Vec2.new(0, 0), 
        0, 
        Vec2.new(
            texture_handles[4].width * 4, 
            texture_handles[4].height * 4
        )
    );

    {
        var i:u32 = 0;
        while (i < 1000) : (i += 1) {

            player_sprites[i] = try api.createSprite(
                texture_handles[0], 
                Vec2.new(-20000, 0), 
                0, 
                Vec2.new(
                    texture_handles[4].width, 
                    texture_handles[4].height
                )
            );

            enemy_sprites[i] = try api.createSprite(
                texture_handles[0], 
                Vec2.new(-20000, 0), 
                0, 
                Vec2.new(
                    texture_handles[4].width, 
                    texture_handles[4].height
                )
            );
        }
    }

}

/// caller must make sure to call deinitUnits
pub fn initAllUnits(allocator: *Allocator) !void {
    // create a test unit for now
    const anim_move = [_]render2d.TextureHandle{ texture_handles[0], texture_handles[1]};
    const anim_attack = [_]render2d.TextureHandle{ texture_handles[0], texture_handles[2]};
    unit_swordman = try Unit.init(
        allocator, 
        &sprites[3], 
        100, 25, 100, 50, 0.5, 
        [2][]const render2d.TextureHandle{&anim_move, &anim_attack}
    );
}

/// caller must make sure to call deinitCastles
pub fn initCastles(allocator: *Allocator) !void {
    const caste_anim_idle = [_]render2d.TextureHandle{texture_handles[4]};
    const caste_anim_attack = [_]render2d.TextureHandle{texture_handles[5]};

    player_castle = try Castle.init(
        allocator,
        &sprites[1],
        unit_swordman,
        &player_sprites,
        2000, 300, 200, 1.5,
        [2][]const render2d.TextureHandle{&caste_anim_idle, &caste_anim_attack},
        Vec2.new(800, -350),
        Vec2.new(-800, 390)
    );

    enemy_castle = try Castle.init(
        allocator,
        &sprites[2],
        unit_swordman,
        &enemy_sprites,
        2000, 300, 200, 1.5,
        [2][]const render2d.TextureHandle{&caste_anim_idle, &caste_anim_attack},
        Vec2.new(-800, 390),
        Vec2.new(800, -350)
    );
    try enemy_castle.spawnUnit();
    try player_castle.spawnUnit();
}

/// caller must make sure to calle deinitGui
pub fn initGui(allocator: *Allocator) !void {
    buttons = ArrayList(Button).init(allocator);
    try buttons.append(Button.init(&sprites[4], texture_handles[6], texture_handles[7], btnCallback));
}

// --------------- TICK ------------------------------------------ //

pub fn globalTick(delta_time: f32) void {
    player_castle.tick(delta_time);
    enemy_castle.tick(delta_time);
    unit_swordman.tick(delta_time);
}


// --------------- DEINITIALIZATION ------------------------------- //

pub fn deinitCastles() void {
    player_castle.deinit();
    enemy_castle.deinit();
}

pub fn deinitUnits() void {
    unit_swordman.deinit();
}

pub fn deinitGui() void {
    buttons.deinit();
}

// ---------------- INPUT HANDLING -------------------------------- //

fn btnCallback() void {
    std.debug.print("hello from button!\n", .{});
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
        @floatCast(f32, event.y) - window_height * 0.5
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
