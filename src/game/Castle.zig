const std = @import("std");
const Allocator = std.mem.Allocator;

const zlm = @import("zlm");

const render2d = @import("../render2d/render2d.zig");
const Sprite = render2d.Sprite;

const Anim = @import("Anim.zig");
const Unit = @import("Unit.zig");
const game_sprite = @import("sprite.zig");

const Self = @This();

pub const State = enum(usize) {
    idle,
    spawning,
};

sprite: *Sprite,
swordman_clone: Unit,
units: [game_sprite.team_size]Unit,

spawn_pos: zlm.Vec2,
enemy_pos: zlm.Vec2,

state: State,

anims: [2]Anim,

health: i32,
damage: i32,
range: i32,
units_spawned: u32,

attack_speed: f32,

unit_getter: fn(number: usize) *render2d.Sprite,

pub fn init(allocator: *Allocator, sprite: *Sprite, unit_getter: fn(number: usize) *render2d.Sprite, swordman_clone: Unit, health: i32, damage: i32, range: i32, attack_speed: f32, textures: [2][]const render2d.TextureHandle, spawn_pos: zlm.Vec2, enemy_pos: zlm.Vec2) !Self {
    var anim: [2]Anim = undefined;
    anim[0] = try Anim.init(allocator, sprite, textures[0], 1);
    errdefer anim[0].deinit();
    anim[1] = try Anim.init(allocator, sprite, textures[1], 1);
    errdefer anim[1].deinit();

    return Self {
        .sprite = sprite,
        .swordman_clone = swordman_clone,
        .health = health,
        .damage = damage,
        .range = range,
        .attack_speed = attack_speed,
        .state = State.idle,
        .anims = anim,
        .spawn_pos = spawn_pos,
        .enemy_pos = enemy_pos,
        .units_spawned = 0,
        .units = undefined,
        .unit_getter = unit_getter,
    };
}

pub fn setState(self: *Self, state: State) void {
    self.state = state;
}

pub fn tick(self: *Self, delta_time: f32) void{
    self.anims[@enumToInt(self.state)].tick(delta_time);

    {
        var i:u32 = 0;
        while (i < self.units_spawned) : (i += 1) {
            self.units[i].tick(delta_time);
        }
    }
}

pub fn spawnUnit(self: *Self) !void{
    if (self.units_spawned < game_sprite.team_size) {
        self.units[self.units_spawned] = try self.swordman_clone.clone(self.unit_getter(self.units_spawned));
        self.units[self.units_spawned].setMove(self.spawn_pos, self.enemy_pos);
        self.units_spawned += 1;
    }
}

pub fn deinit(self: Self) void {
    self.anims[0].deinit();
    self.anims[1].deinit();
    {   
        var i:u32 = 0;
        while (i < self.units_spawned) : (i += 1) {
            self.units[i].deinit();
        }
    }
}

